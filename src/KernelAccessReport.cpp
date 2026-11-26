#include "llvm/ADT/SmallVector.h"
#include "llvm/Analysis/AliasAnalysis.h"
#include "llvm/Analysis/LoopInfo.h"
#include "llvm/Analysis/MemoryLocation.h"
#include "llvm/Analysis/OptimizationRemarkEmitter.h"
#include "llvm/Analysis/ScalarEvolution.h"
#include "llvm/Analysis/ScalarEvolutionExpressions.h"
#include "llvm/Config/llvm-config.h"
#include "llvm/IR/DataLayout.h"
#include "llvm/IR/DiagnosticInfo.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/PassManager.h"
#include "llvm/Passes/PassBuilder.h"
#include "llvm/Plugins/PassPlugin.h"
#include "llvm/Support/Compiler.h"
#include "llvm/Support/TypeSize.h"

#include <cstdint>
#include <string>

using namespace llvm;

namespace {

constexpr char PassName[] = "kernel-access-report";

struct MemoryAccess {
  const Instruction *Inst;
  const Value *Pointer;
  Type *AccessType;
  MemoryLocation Location;
  unsigned Index;
  bool IsLoad;
};

template <typename AnchorT>
void emitRemark(OptimizationRemarkEmitter &ORE, StringRef Name,
                const AnchorT *Anchor, const Twine &Message) {
  const std::string Text = Message.str();
  ORE.emit(OptimizationRemarkAnalysis(PassName, Name, Anchor)
           << StringRef(Text));
}

StringRef aliasResultName(AliasResult Result) {
  if (Result == AliasResult::NoAlias)
    return "NoAlias";
  if (Result == AliasResult::MustAlias)
    return "MustAlias";
  if (Result == AliasResult::PartialAlias)
    return "MayAlias (partial overlap)";
  return "MayAlias";
}

bool widthRequiresDataLayout(Type *Ty) {
  if (Ty->isPointerTy() || Ty->isAggregateType())
    return true;
  if (const auto *VectorTy = dyn_cast<VectorType>(Ty))
    return widthRequiresDataLayout(VectorTy->getElementType());
  return false;
}

std::string describeWidth(Type *Ty, const DataLayout &DL) {
  if (DL.isDefault() && widthRequiresDataLayout(Ty))
    return "unknown (module has no data layout for this access type)";

  TypeSize Size = DL.getTypeStoreSize(Ty);
  if (Size.isScalable())
    return (Twine("scalable (minimum ") + Twine(Size.getKnownMinValue()) +
            " bytes)")
        .str();
  return (Twine(Size.getFixedValue()) + " bytes").str();
}

std::string describeStride(const Value *Pointer, Loop &L, ScalarEvolution &SE) {
  const SCEV *Address = SE.getSCEV(const_cast<Value *>(Pointer));
  if (SE.isLoopInvariant(Address, &L))
    return "0 bytes/iteration";

  const auto *Recurrence = dyn_cast<SCEVAddRecExpr>(Address);
  if (!Recurrence || Recurrence->getLoop() != &L)
    return "unknown (address is not a recurrence for this loop)";
  if (!Recurrence->isAffine())
    return "unknown (address recurrence is not affine)";

  const auto *Step = dyn_cast<SCEVConstant>(Recurrence->getStepRecurrence(SE));
  if (!Step)
    return "unknown (byte step is not constant)";

  const APInt &StepValue = Step->getAPInt();
  if (!StepValue.isSignedIntN(64))
    return "unknown (byte step does not fit in 64 bits)";

  return (Twine(StepValue.getSExtValue()) + " bytes/iteration").str();
}

std::string accessLabel(const MemoryAccess &Access) {
  return (Twine("access#") + Twine(Access.Index)).str();
}

std::string unsupportedLoopReason(Loop &L) {
  if (!L.getSubLoops().empty())
    return "nested loops are unsupported";
  if (!L.getLoopPreheader())
    return "loop has no unique preheader";
  if (!L.getLoopLatch())
    return "loop has no unique latch";

  SmallVector<BasicBlock *, 4> ExitingBlocks;
  L.getExitingBlocks(ExitingBlocks);
  if (ExitingBlocks.size() != 1)
    return "loop must have exactly one exiting block";

  SmallVector<BasicBlock *, 4> ExitBlocks;
  L.getExitBlocks(ExitBlocks);
  if (ExitBlocks.size() != 1)
    return "loop must have exactly one exit block";

  if (!L.isLoopSimplifyForm())
    return "loop is not in LoopSimplify form";
  return {};
}

class KernelAccessReportPass : public PassInfoMixin<KernelAccessReportPass> {
public:
  PreservedAnalyses run(Function &F, FunctionAnalysisManager &AM) {
    LoopInfo &LI = AM.getResult<LoopAnalysis>(F);
    OptimizationRemarkEmitter &ORE =
        AM.getResult<OptimizationRemarkEmitterAnalysis>(F);

    unsigned TopLevelLoopCount = 0;
    Loop *OnlyTopLevelLoop = nullptr;
    for (Loop *TopLevelLoop : LI) {
      ++TopLevelLoopCount;
      OnlyTopLevelLoop = TopLevelLoop;
    }

    if (TopLevelLoopCount == 0) {
      emitRemark(ORE, "Unsupported", &F,
                 Twine("function=") + F.getName() +
                     " unsupported reason=no natural loop");
      return PreservedAnalyses::all();
    }

    if (TopLevelLoopCount != 1) {
      emitRemark(ORE, "Unsupported", &F,
                 Twine("function=") + F.getName() +
                     " unsupported reason=expected one top-level loop; found " +
                     Twine(TopLevelLoopCount));
      return PreservedAnalyses::all();
    }

    Loop &L = *OnlyTopLevelLoop;
    const std::string ShapeProblem = unsupportedLoopReason(L);
    if (!ShapeProblem.empty()) {
      emitRemark(ORE, "Unsupported", L.getHeader()->getTerminator(),
                 Twine("function=") + F.getName() +
                     " unsupported reason=" + ShapeProblem);
      return PreservedAnalyses::all();
    }

    ScalarEvolution &SE = AM.getResult<ScalarEvolutionAnalysis>(F);
    AAResults &AA = AM.getResult<AAManager>(F);
    const DataLayout &DL = F.getParent()->getDataLayout();

    const unsigned TripCount = SE.getSmallConstantTripCount(&L);
    const std::string TripCountText =
        TripCount ? (Twine("known(") + Twine(TripCount) + ")").str()
                  : "unknown";
    emitRemark(ORE, "Loop", L.getHeader()->getTerminator(),
               Twine("function=") + F.getName() + " loop trip-count=" +
                   TripCountText + " loop-carried-dependence=not-analyzed");

    SmallVector<MemoryAccess, 8> Accesses;
    unsigned AccessIndex = 0;
    for (BasicBlock *BB : L.blocks()) {
      for (const Instruction &I : *BB) {
        if (const auto *LI = dyn_cast<LoadInst>(&I)) {
          Accesses.push_back({&I, LI->getPointerOperand(), LI->getType(),
                              MemoryLocation::get(LI), AccessIndex++, true});
          continue;
        }
        if (const auto *SI = dyn_cast<StoreInst>(&I)) {
          Accesses.push_back({&I, SI->getPointerOperand(),
                              SI->getValueOperand()->getType(),
                              MemoryLocation::get(SI), AccessIndex++, false});
          continue;
        }
        if (I.mayReadOrWriteMemory()) {
          emitRemark(ORE, "UnsupportedMemoryAccess", &I,
                     Twine("function=") + F.getName() +
                         " unsupported memory-access=" + I.getOpcodeName() +
                         " reason=only-loads-and-stores-are-reported");
        }
      }
    }

    if (Accesses.empty()) {
      emitRemark(ORE, "Unsupported", L.getHeader()->getTerminator(),
                 Twine("function=") + F.getName() +
                     " unsupported reason=loop-has-no-load-or-store");
      return PreservedAnalyses::all();
    }

    for (const MemoryAccess &Access : Accesses) {
      const auto *PointerType =
          dyn_cast<llvm::PointerType>(Access.Pointer->getType());
      if (!PointerType) {
        emitRemark(ORE, "UnsupportedMemoryAccess", Access.Inst,
                   Twine("function=") + F.getName() + " " +
                       accessLabel(Access) +
                       " unsupported reason=access-operand-is-not-a-pointer");
        continue;
      }

      const std::string Width = describeWidth(Access.AccessType, DL);
      const std::string Stride = describeStride(Access.Pointer, L, SE);
      emitRemark(ORE, "Access", Access.Inst,
                 Twine("function=") + F.getName() + " " + accessLabel(Access) +
                     (Access.IsLoad ? " load" : " store") + " width=" + Width +
                     " address-space=" + Twine(PointerType->getAddressSpace()) +
                     " stride=" + Stride);
    }

    for (size_t I = 0; I < Accesses.size(); ++I) {
      for (size_t J = I + 1; J < Accesses.size(); ++J) {
        const AliasResult Result =
            AA.alias(Accesses[I].Location, Accesses[J].Location);
        emitRemark(ORE, "Alias", Accesses[J].Inst,
                   Twine("function=") + F.getName() + " alias " +
                       accessLabel(Accesses[I]) + " " +
                       accessLabel(Accesses[J]) + " = " +
                       aliasResultName(Result));
      }
    }

    return PreservedAnalyses::all();
  }
};

} // namespace

extern "C" LLVM_ATTRIBUTE_WEAK PassPluginLibraryInfo llvmGetPassPluginInfo() {
  return {LLVM_PLUGIN_API_VERSION, "KernelForge", LLVM_VERSION_STRING,
          [](PassBuilder &PB) {
            PB.registerPipelineParsingCallback(
                [](StringRef Name, FunctionPassManager &FPM,
                   ArrayRef<PassBuilder::PipelineElement>) {
                  if (Name != PassName)
                    return false;
                  FPM.addPass(KernelAccessReportPass());
                  return true;
                });
          }};
}
