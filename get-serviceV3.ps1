## Script check in list of servers a list of services
## Post json messages in Teams Group
## Post or consult incidents in API Tickets
## Post number of ticket in Teams Group in case of opem
## Opem new ticket in case not opened
## Notify Group Teams for number ticket
## Execution new task scheduler with powershell -command "& 'Path_of_script' 'Path_of_config_file'"


##XML Parameters
param(
[string]$configPath
)

##Change path
Set-Location $configPath

##Import Function
. .\import-xml.ps1

$Config = Import-XMLConfig -ConfigPath $configPath\config.xml

Write-Output $Config

##Start Log
$logFile = $Config.log + (Get-Date).ToString('yyyyMMddHHmm') + ".txt" 

Start-Transcript -Path $logFile

##URL Teams group
$webHook = $Config.url

##Variable to platform
$plataforma = $Config.plat

$filepath =  ".\im.txt"

##list servers
foreach($servers in $Config.server){

    Write-Output $servers
    
    ##List services
    foreach($service in $Config.service){

        Write-Output $service

        ##Get incident status
        $check = Get-Service -ComputerName $servers -DisplayName $service | Select-Object Status
    
        Write-Output $check

        $serv = $check.status
            
            ##Condition is Running ? 
            if($serv -ne "Running") {
                ##Fail message in Teams Group
                $alert = ConvertTo-Json -Depth 1 @{
                text = "`nServico: $service Status: $serv Servidor: $servers"
                title = "Servico do $plataforma"
                }
                ##Post Teams
                $response = Invoke-RestMethod -ContentType "application/json" -Method Post -body $alert -Uri $webHook
                Write-Output $response

                ##Get number of incidente
                $im = Get-Content -Path $filepath

                ##Variable to acces API of incidents
                $username = 'svcacc_tiim'
                $password = 'mudar$123'
                $credPair = "$($username):$($password)"
                $encodedCredentials = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($credPair))
                $headers = @{ Authorization = "Basic $encodedCredentials" }

                ##Condition of no incident exist
                if($im -ne $null){

                    $consult = $Config.sm + "/" + $im

                    ##Get im status
                    $getstatus = Invoke-RestMethod -Method Get -Uri $consult -Headers $headers -UseBasicParsing

                    $st = $getstatus.Incident | Select-Object status

                    $sts = $st.status
                    
                    ##Incidente is opem or Work  
                    if($st -eq "Opem" -or $st -eq "Work in progress"){

                        ##Message in Teams group to incident opem
                        $alert2 = ConvertTo-Json -Depth 1 @{
                        text = "`nService: $service Status: $serv Server: $servers Incident $im"
                        title = "Service $plataforma"
                          }
                        
                        ##Post message in teams 
                        $response2 = Invoke-RestMethod -ContentType "application/json" -Method Post -body $alert2 -Uri $webHook
                        Write-Outpute $response2
                    }              
                    
                    ##Incident is close this opem new incident
                    elseif ($sts -eq "Closed") {
                        ##Json to parameters to API incident
                        $alert3 = ConvertTo-Json -Depth 1 @{
                            Incident  = @{
                            category = $Config.category
                            company = $Config.company
                            alternatecontact = $Config.alternatecontact
                            assignmentgroup = $Config.assignmentgroup
                            impact = $Config.impact
                            configurationitem = $Config.configurationitem
                            producttype = $Config.producttype
                            symptom = $Config.symptom
                            subcategory = $Config.subcategory
                            briefdesc = "$servers $service"
                            urgency = $Config.urgency
                            description = "Alarm of $service status $serv server $servers"
                            }
                        }
                        
                        ##Post json in API to incidents
                        $response3 = Invoke-RestMethod  -ContentType "application/json" -Method Post -body $alert3 -Uri $Config.sm -Headers $headers -UseBasicParsing
             
                        Write-Output $response3
                    }
                    
                    ##Get number to incident
                    $im = $response3.Incident | Select-Object number

                    $number = $im.number
                    
                    ##Create a texte file 
                    $number | Out-File -FilePath $filepath
                }

                ##Condition of opem incident with no exist other
                Else{
                    ##Json parameters of API incident
                    $alert4 = ConvertTo-Json -Depth 1 @{
                        Incident  = @{
                        category = $Config.category
                        company = $Config.company
                        alternatecontact = $Config.alternatecontact
                        assignmentgroup = $Config.assignmentgroup
                        impact = $Config.impact
                        configurationitem = $Config.configurationitem
                        producttype = $Config.producttype
                        symptom = $Config.symptom
                        subcategory = $Config.subcategory
                        briefdesc = "$servers $service"
                        urgency = $Config.urgency
                        description = "Alarm of $service status $serv server $servers"
                        }
                    }
                    ##Post incidente in Teams group
                    $response4 = Invoke-RestMethod  -ContentType "application/json" -Method Post -body $alert4 -Uri $Config.sm -Headers $headers -UseBasicParsing
         
                    Write-Output $response4
                    
                    ##Select incident number
                    $im = $response4.Incident | Select-Object number

                    $number = $im.number
                    
                    ##Record number in texte file
                    $number | Out-File -FilePath $filepath
                }
            }
            ##Condition service is running             
            elseif ($serv -eq "Running") {
                ##Path of logs and history incidente opened
                $dest = $Config.log + "\im" + (Get-Date).ToString('yyyyMMddHHmm') + ".txt"
                ##Copy incident opened in logs pah
                Copy-Item -Path $filepath -Destination $dest
                ##Remove incidente existing
                Get-ChildItem -Path $filepath | Remove-Item -Force
                Write-Output "Remove incident"
            }
    }
}
