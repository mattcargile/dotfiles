class UtilityCommandParameterInfo {
    [string]$Set
    [System.Collections.ObjectModel.ReadOnlyCollection[string]]$Aliases
    [int]$Position
    [bool]$IsDynamic
    [bool]$IsMandatory
    [bool]$ValueFromPipeline
    [bool]$ValueFromPipelineByPropertyName
    [bool]$ValueFromRemainingArguments
    [type]$Type
    [string]$Name
    [System.Collections.ObjectModel.ReadOnlyCollection[System.Attribute]]$Attributes
    [bool]$IsDefaultSet
}
