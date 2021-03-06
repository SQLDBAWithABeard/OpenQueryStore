$script:ModuleName = 'OpenQueryStore'
# Removes all versions of the module from the session before importing
Get-Module $ModuleName | Remove-Module
$ModuleBase = Split-Path -Parent $MyInvocation.MyCommand.Path
# For tests in .\Tests subdirectory
if ((Split-Path $ModuleBase -Leaf) -eq 'Tests') {
    $ModuleBase = Split-Path $ModuleBase -Parent
}
## this variable is for the VSTS tasks and is to be used for refernecing any mock artifacts
$Env:ModuleBase = $ModuleBase
Import-Module $ModuleBase\$ModuleName.psd1 -PassThru -ErrorAction Stop | Out-Null
Describe "Basic function unit tests" -Tags Build , Unit{

}
InModuleScope -ModuleName $ModuleName -ScriptBlock {
    Describe "Testing Install-OpenQueryStore command" -Tags Install {
        It "Command Install-OpenQueryStore exists" {
            Get-Command Install-OpenQueryStore -ErrorAction SilentlyContinue | Should Not BE NullOrEmpty
        }
        Context "Install-OpenQueryStore input" {
            function Invoke-Catch{}
            Mock Invoke-Catch {}
            $results = (Get-Content $PSScriptRoot\json\SQL2012version.json) -join "`n" | ConvertFrom-Json 
            Mock Connect-DbaInstance {$results}
            Mock Get-DbaDatabase -ParameterFilter { $Database -and $Database -eq "WrongDatabase" } {}
            Mock Get-DbaDatabase -ParameterFilter { $Database -and $Database -eq "OQSDatabase" } {'A Database'}
            It "Should call the Invoke-Catch if there is no database"{
                Install-OpenQueryStore -SqlInstance Dummy -Database WrongDatabase -SchedulerType 'Service Broker'
                $assertMockParams = @{
                    'CommandName' = 'Invoke-Catch'
                    'Times'       = 1
                    'Exactly'     = $true
                }
                Assert-MockCalled @assertMockParams 
            }
            It "Should Not call Invoke-Catch if there is a database" {
                Install-OpenQueryStore -SqlInstance Dummy -Database OQSDatabase -SchedulerType 'Service Broker'
                $assertMockParams = @{
                    'CommandName' = 'Invoke-Catch'
                    'Times'       = 1
                    'Exactly'     = $true
                }
                Assert-MockCalled @assertMockParams 
            
            }
            It "Should accept a value for OQSMode of classic" {
                {Install-OpenQueryStore -SqlInstance Dummy -DatabaseName OQSDatabase -OQSMode 'Classic'-SchedulerType 'Service Broker'} | Should Not Throw
            }
            
            It "Should accept a value for OQS Mode of centralized" {
                {Install-OpenQueryStore -SqlInstance Dummy -DatabaseName OQSDatabase -OQSMode 'Centralized' -SchedulerType 'Service Broker'} | Should Not Throw
            }            
            It "Should accept a value for SchedulerType of Service Broker" {
                {Install-OpenQueryStore -SqlInstance Dummy -DatabaseName OQSDatabase -OQSMode 'Centralized' -SchedulerType 'Service Broker' } | Should Not Throw
            }            
            It "Should accept a value for SchedulerType of SQL Agent" {
                {Install-OpenQueryStore -SqlInstance Dummy -DatabaseName OQSDatabase -OQSMode 'Centralized' -SchedulerType 'SQL Agent' } | Should Not Throw
            }            
        }
        Context "Version Support" {
            function Invoke-Catch{}
            Mock Invoke-Catch {break}
            #We only support between SQL Server 2008 (v10.X.X) and SQL Server 2014
            It "Should Break for SQL 2017" {
                $results = (Get-Content $PSScriptRoot\json\SQL2017version.json) -join "`n" | ConvertFrom-Json 
                Mock Connect-DbaInstance {$results}
                
                Install-OpenQueryStore -SqlInstance Dummy -Database Dummy -SchedulerType 'Service Broker'| Should Be 
            }
            It "Should Break for SQL 2016" {
                $results = (Get-Content $PSScriptRoot\json\SQL2016version.json) -join "`n" | ConvertFrom-Json 
                Mock Connect-DbaInstance {$results}
                
                Install-OpenQueryStore -SqlInstance Dummy -Database Dummy -SchedulerType 'Service Broker' | Should Be 
            }
            It "Should Break for SQL 2005" {
                $results = (Get-Content $PSScriptRoot\json\SQL2005version.json) -join "`n" | ConvertFrom-Json 
                Mock Connect-DbaInstance {$results}
                
                Install-OpenQueryStore -SqlInstance Dummy -Database Dummy -SchedulerType 'Service Broker' | Should Be 
            }
            It "Should Break for SQL 2000" {
                $results = (Get-Content $PSScriptRoot\json\SQL2000version.json) -join "`n" | ConvertFrom-Json 
                Mock Connect-DbaInstance {$results}
                
                Install-OpenQueryStore -SqlInstance Dummy -Database Dummy -SchedulerType 'Service Broker'| Should Be 
            }
            It 'Checks the Mock was called for Connect-DbaInstance' {
                $assertMockParams = @{
                    'CommandName' = 'Connect-DbaInstance'
                    'Times'       = 4
                    'Exactly'     = $true
                }
                Assert-MockCalled @assertMockParams 
            }
            It 'Checks the Mock was called for Invoke-Catch' {
                $assertMockParams = @{
                    'CommandName' = 'Invoke-Catch'
                    'Times'       = 4
                    'Exactly'     = $true
                }
                Assert-MockCalled @assertMockParams 
            }
        }
        Context "Install-OpenQueryStore Execution" {
            Mock Get-Module {}
            Mock Write-Warning {}
            It "Should write a warning if dbatools module not available"{      
                Install-OpenQueryStore -SqlInstance Dummy -Database Dummy -SchedulerType 'Service Broker'| Should Not Throw
            }
            It 'Checks the Mock was called for Write-Warning' {
                $assertMockParams = @{
                    'CommandName' = 'Write-Warning'
                    'Times'       = 1
                    'Exactly'     = $true
                }
                Assert-MockCalled @assertMockParams 
            }
            It 'Checks the Mock was called for Get-Module' {
                $assertMockParams = @{
                    'CommandName' = 'Get-Module'
                    'Times'       = 1
                    'Exactly'     = $true
                }
                Assert-MockCalled @assertMockParams 
            }
        }
        Context "Install-OpenQueryStore Output" {

        }
    }
}
