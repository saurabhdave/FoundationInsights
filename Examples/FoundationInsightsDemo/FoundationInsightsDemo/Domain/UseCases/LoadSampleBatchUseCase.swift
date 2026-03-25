// MARK: - Protocol

/// Contract for loading a pre-canned log batch by sample type.
protocol LoadSampleBatchUseCaseProtocol: Sendable {
    func execute(for sample: SampleLogBatches.Sample) -> String
}

// MARK: - Default Implementation

/// Returns the static log text for the given sample type.
struct LoadSampleBatchUseCase: LoadSampleBatchUseCaseProtocol {
    func execute(for sample: SampleLogBatches.Sample) -> String {
        sample.logText
    }
}
