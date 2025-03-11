$DiasInatividade = 90 # Define o número de dias de inatividade para considerar uma conta como inativa
$DataLimite = (Get-Date).AddDays(-$DiasInatividade) # Calcula a data limite (a data atual menos os dias de inatividade)
$CaminhoArquivoCSV = "C:\Users\sherlock\Relatorios\ContasInativas.csv" # Caminho para o arquivo CSV contendo as informações das contas inativas
$CaminhoRelatorio = "C:\Users\sherlock\Relatorios\ContasInativas_Resultado.csv" # Caminho para o arquivo de relatório onde os resultados serão salvos


# Verifica se o diretório de relatórios existe, se não, cria o diretório
If (!(Test-Path "C:\Users\sherlock\Relatorios")) {
    New-Item -ItemType Directory -Path "C:\Users\sherlock\Relatorios"
}

$UsuariosCSV = Import-Csv -Path $CaminhoArquivoCSV -Delimiter ";" # Importa o arquivo CSV com os usuários a serem processados
$ContasInativas = Get-ADUser -Filter {LastLogonDate -lt $DataLimite -and Enabled -eq $true} -Properties LastLogonDate # Busca as contas inativas no Active Directory que não foram logadas nos últimos $DiasInatividade dias


# Verifica se existem contas inativas
if ($ContasInativas) {
    # Exporta as contas inativas para um arquivo CSV com o nome, login e data do último login
    $ContasInativas | Select-Object Name, SamAccountName, LastLogonDate | Export-Csv -Path $CaminhoRelatorio -NoTypeInformation
    Write-Host "Relatório de contas inativas gerado em $CaminhoRelatorio"

    # Para cada conta inativa, desativa a conta no Active Directory
    foreach ($Conta in $ContasInativas) {
        # Desativa a conta
        Disable-ADAccount -Identity $Conta.SamAccountName
        Write-Host "Conta bloqueada: $($Conta.SamAccountName)"
    }

    Write-Host "`nProcesso concluído. Contas inativas foram bloqueadas."
} else {
    Write-Host "Não existem contas inativas no momento."     # Se não houver contas inativas, exibe uma mensagem informando
}

$ContasDesabilitadas = Get-ADUser -Filter {Enabled -eq $false} -Properties SamAccountName, Name # Busca as contas que já estão desabilitadas no Active Directory

# Verifica se existem contas desabilitadas
if ($ContasDesabilitadas) {
    Write-Host "`nContas já desabilitadas:"
    # Exibe as contas desabilitadas em formato de tabela
    $ContasDesabilitadas | Select-Object Name, SamAccountName | Format-Table -AutoSize
} else {
    Write-Host "`nNenhuma conta desabilitada encontrada."  # Se não houver contas desabilitadas, exibe uma mensagem informando
}

# Processa cada usuário no arquivo CSV e desabilita as contas correspondentes
foreach ($UsuarioCSV in $UsuariosCSV) {
    $nomeUsuario = $UsuarioCSV.Nome
    $grupoUsuario = $UsuarioCSV.Grupo

    # Busca o usuário no Active Directory pelo SamAccountName
    $user = Get-ADUser -Filter {SamAccountName -eq $nomeUsuario} -Properties SamAccountName, Enabled
    
    # Se o usuário for encontrado
    if ($user) {
        # Verifica se a conta está habilitada
        if ($user.Enabled) {
            # Desativa a conta
            Disable-ADAccount -Identity $user
            Write-Host "Conta $nomeUsuario desativada."
        } else {
            Write-Host "Conta $nomeUsuario já está desativada."
        }
    } else {
        Write-Host "Usuário $nomeUsuario não encontrado no Active Directory." # Se o usuário não for encontrado, exibe uma mensagem informando

    }
}

Write-Host "`nProcesso de desativação de contas do arquivo CSV concluído."
