$arquivo = "C:\Users\sherlock\Relatorios\lista.csv"
$relatorio = "C:\Users\sherlock\Relatorios\fora.txt"

if (-not (Get-Module -ListAvailable -Name ActiveDirectory)) { 
    Write-Host "AD não encontrado"
    exit 
}

$demitidos = Import-Csv -Path $arquivo -Delimiter ";"

if (Test-Path $relatorio) {
    Remove-Item $relatorio
}

$demitidos | ForEach-Object {
    $nomeUsuario = $_.Nome
    $grupoUsuario = $_.Grupo

    $user = Get-ADUser -Filter {SamAccountName -eq $nomeUsuario} -Properties MemberOf, Enabled
    if ($user) {
        if ($user.Enabled) {
            Disable-ADAccount -Identity $user

            $user.MemberOf | ForEach-Object { 
                Remove-ADGroupMember -Identity $_ -Members $user -Confirm:$false 
            }

            $logEntry = [PSCustomObject]@{
                Usuario = $nomeUsuario
                Status = "Desativado"
                Data = Get-Date
                Grupo = $grupoUsuario
            }

            $logEntry | Export-Csv -Path $relatorio -Append -NoTypeInformation

            Write-Host "$nomeUsuario foi desativado e removido dos grupos."
        }
        else {
            Write-Host "O $nomeUsuario ja estava desativado"
        }
    }
    else {
        Write-Host " $nomeUsuario nao encontrado no AD"
    }
}

Write-Host "Processo concluido $relatorio."
