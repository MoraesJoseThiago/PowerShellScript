$periodoInatividade = 10 # ta em minutos! Depois vou mudar para 90 dias
$limiteData = (Get-Date).AddMinutes(-$periodoInatividade)

# Caminho do relatório
$relatorio = "C:\relatorio_usuarios_inativos.csv"

# Verificar contas inativas
$usuarios = Get-ADUser -Filter * -Properties LastLogonDate, Enabled
$computadores = Get-ADComputer -Filter * -Properties LastLogonDate, Enabled
$contasInativas = @()

# Checar contas de usuário e computador
foreach ($usuario in $usuarios) {
    if ($usuario.LastLogonDate -lt $limiteData -and $usuario.Enabled) {
        $contasInativas += [PSCustomObject]@{
            Tipo = "Usuário"
            Nome = $usuario.SamAccountName
            UltimoLogin = $usuario.LastLogonDate
        }
    }
}

foreach ($computador in $computadores) {
    if ($computador.LastLogonDate -lt $limiteData -and $computador.Enabled) {
        $contasInativas += [PSCustomObject]@{
            Tipo = "Computador"
            Nome = $computador.Name
            UltimoLogin = $computador.LastLogonDate
        }
    }
}

# Gerar o relatório em CSV
$contasInativas | Export-Csv -Path $relatorio -NoTypeInformation
Write-Host "Relatório gerado: $relatorio"

# Desativar as contas inativas
foreach ($conta in $contasInativas) {
    if ($conta.Tipo -eq "Usuário") {
        Disable-ADAccount -Identity $conta.Nome
        Write-Host "Conta de usuário desativada: $($conta.Nome)"
    } elseif ($conta.Tipo -eq "Computador") {
        Disable-ADAccount -Identity $conta.Nome
        Write-Host "Conta de computador desativada: $($conta.Nome)"
    }
}

# Simulação de envio de e-mail
Send-MailMessage -To "admin@dominio.com" -Subject "Contas Inativas" -Body "As contas inativas foram desativadas. Consulte o relatório gerado." -SmtpServer "smtp.dominio.com"
Write-Host "Notificação enviada ao administrador."
