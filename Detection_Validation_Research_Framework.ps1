#requires -Version 5.1
[CmdletBinding()]
param([Parameter(Mandatory)][string]$InputCsv,[string]$OutputPath)

$stamp=Get-Date -Format 'yyyyMMdd_HHmmss'
if([string]::IsNullOrWhiteSpace($OutputPath)){$OutputPath=Join-Path ([Environment]::GetFolderPath('Desktop')) 'Detection_Validation_Research'}
New-Item -Path $OutputPath -ItemType Directory -Force|Out-Null
if(-not(Test-Path $InputCsv)){Write-Error 'Input CSV not found.';return}

$rows=Import-Csv $InputCsv|ForEach-Object{
 $confidence=0
 [void][int]::TryParse($_.Confidence,[ref]$confidence)
 $expectedPresent=-not [string]::IsNullOrWhiteSpace($_.ExpectedEvidence)
 $observedPresent=-not [string]::IsNullOrWhiteSpace($_.ObservedEvidence)
 $validationState=if($_.Status){$_.Status}elseif($expectedPresent -and $observedPresent){'Validated'}else{'Research'}
 [PSCustomObject]@{
  ValidationId=$_.ValidationId
  DetectionName=$_.DetectionName
  TechniqueId=$_.TechniqueId
  DataSource=$_.DataSource
  ExpectedEvidence=$_.ExpectedEvidence
  ObservedEvidence=$_.ObservedEvidence
  FalsePositiveNotes=$_.FalsePositiveNotes
  Status=$validationState
  Confidence=$confidence
  Owner=$_.Owner
  EvidenceComplete=($expectedPresent -and $observedPresent)
 }
}

$byStatus=$rows|Group-Object Status|ForEach-Object{[PSCustomObject]@{Status=$_.Name;Count=$_.Count;AverageConfidence=[math]::Round((($_.Group.Confidence|Measure-Object -Average).Average),1)}}
$bySource=$rows|Group-Object DataSource|Sort-Object Count -Descending|ForEach-Object{[PSCustomObject]@{DataSource=$_.Name;Cases=$_.Count;Validated=@($_.Group|Where-Object Status -eq 'Validated').Count}}
$gaps=$rows|Where-Object{(-not $_.EvidenceComplete) -or $_.Confidence -lt 70}|Select-Object ValidationId,DetectionName,TechniqueId,DataSource,Status,Confidence,EvidenceComplete,Owner
$summary=[PSCustomObject]@{TotalCases=@($rows).Count;Validated=@($rows|Where-Object Status -eq 'Validated').Count;Research=@($rows|Where-Object Status -ne 'Validated').Count;EvidenceGaps=@($gaps).Count;AverageConfidence=[math]::Round((($rows.Confidence|Measure-Object -Average).Average),1);Generated=Get-Date}

$rows|Export-Csv (Join-Path $OutputPath "validation_register_$stamp.csv") -NoTypeInformation -Encoding UTF8
$byStatus|Export-Csv (Join-Path $OutputPath "status_summary_$stamp.csv") -NoTypeInformation -Encoding UTF8
$bySource|Export-Csv (Join-Path $OutputPath "data_source_summary_$stamp.csv") -NoTypeInformation -Encoding UTF8
$gaps|Export-Csv (Join-Path $OutputPath "validation_gaps_$stamp.csv") -NoTypeInformation -Encoding UTF8
@{Summary=$summary;StatusSummary=$byStatus;DataSourceSummary=$bySource;ValidationGaps=$gaps;Cases=$rows}|ConvertTo-Json -Depth 8|Set-Content (Join-Path $OutputPath "detection_validation_$stamp.json") -Encoding UTF8
$html="<h1>Detection Validation Research</h1><p>Generated $(Get-Date)</p><h2>Summary</h2>$(@($summary)|ConvertTo-Html -Fragment)<h2>Status</h2>$($byStatus|ConvertTo-Html -Fragment)<h2>Data Sources</h2>$($bySource|ConvertTo-Html -Fragment)<h2>Validation Gaps</h2>$($gaps|ConvertTo-Html -Fragment)"
$html|ConvertTo-Html -Title 'Detection Validation Research'|Set-Content (Join-Path $OutputPath "detection_validation_$stamp.html") -Encoding UTF8
$summary|Format-List
Write-Host "Reports saved to: $OutputPath" -ForegroundColor Green
