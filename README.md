# Detection Validation Research Framework

A defensive research framework for documenting detection assumptions, required telemetry, validation evidence, and tuning outcomes.

## Research areas

- Detection hypothesis and scope
- Required data sources and event coverage
- Validation evidence and expected observations
- False-positive analysis
- Confidence and maturity scoring
- ATT&CK references
- Analyst notes and tuning history

## Main tool

```powershell
powershell.exe -ExecutionPolicy Bypass -File .\Detection_Validation_Research_Framework.ps1 -InputCsv .\research\validation-cases.csv
```

## Required CSV columns

`ValidationId`, `DetectionName`, `TechniqueId`, `DataSource`, `ExpectedEvidence`, `ObservedEvidence`, `FalsePositiveNotes`, `Status`, `Confidence`, `Owner`

## Safety

Research and documentation only. The framework does not execute offensive techniques or modify security controls.
