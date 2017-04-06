@{
    ModuleVersion="0.0.0.2"
    Description="A Wrapper for Microsoft's SQL Server PowerShell Extensions Snapins"
    Author="Chad Miller, Andrey Shchekin"
    Copyright="© 2010, Chad Miller, released under the Ms-PL"
    CompanyName="http://sev17.com"
    CLRVersion="2.0"
    FormatsToProcess="SQLProvider.Format.ps1xml"
    NestedModules="Microsoft.SqlServer.Management.PSSnapins.dll","Microsoft.SqlServer.Management.PSProvider.dll"
    TypesToProcess="SQLProvider.Types.ps1xml"
    ScriptsToProcess="sqlps.Variables.ps1"
}