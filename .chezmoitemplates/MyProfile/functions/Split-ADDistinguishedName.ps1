function Split-ADDistinguishedName {
    <#
    .SYNOPSIS
        Split a distinguishedName into named pieces.

    .DESCRIPTION
        Split a distinguishedName into Name, ParentDN, ParentName, and DomainComponent.

    .EXAMPLE
        Split-DistinguishedName 'OU=somewhere,DC=domain,DC=com'
    
        Returns an object containing each of the elements of the DN.
    
    .EXAMPLE
        'CN=last\, first,OU=somewhere,DC=domain,DC=com' | Split-DistinguishedName -Property ParentDN
        
        Returns the parent distinguishedName, OU=somewhere,DC=domain,DC=com
    #>

    [CmdletBinding(DefaultParameterSetName = 'ToObject')]
    [Alias('Split-DN', 'sldn')]
    param (
        [Parameter(Mandatory, Position = 1, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('DN')]
        [string]$DistinguishedName,
        
        [Parameter(Mandatory, ParameterSetName = 'Leaf')]
        [switch]$Leaf,
        
        [Parameter(Mandatory, ParameterSetName = 'Parent')]
        [switch]$Parent,
        
        [Parameter(Mandatory, ParameterSetName = 'GetProperty')]
        [ValidateSet('Name', 'ParentDN', 'ParentName', 'DomainComponent')]
        [string]$Property
    )

    begin {
        if ($Leaf) {
            $Property = 'Name'
        }
        if ($Parent) {
            $Property = 'ParentDN'
        }
    }

    process {
        if ($DistinguishedName -match '^(?:CN|OU|DC)=(?<Name>.*?),(?<ParentDN>(?:CN|OU|DC)=(?<ParentName>.*?(?=,(?:CN|OU|DC))).*?(?<DomainComponent>DC=.*))') {
            if ($Property) {
                $matches[$Property]
            } else {
                $matches.Remove(0)
                [PSCustomObject]$matches
            }
        }
    }
}