# Caminho do arquivo CSV contendo a lista de usuários a serem processados
$arquivo = "C:\Users\sherlock\Relatorios\lista.csv"

# Caminho do arquivo de relatório onde as informações dos usuários desativados serão armazenadas
$relatorio = "C:\Users\sherlock\Relatorios\fora.txt"

# Verifica se o módulo ActiveDirectory está disponível. Caso contrário, exibe uma mensagem e encerra o script
if (-not (Get-Module -ListAvailable -Name ActiveDirectory)) { 
    Write-Host "AD não encontrado"
    exit 
}

# Importa os dados do arquivo CSV, usando ";" como delimitador, e os armazena na variável $demitidos
$demitidos = Import-Csv -Path $arquivo -Delimiter ";"

# Verifica se o arquivo de relatório já existe. Se existir, o remove antes de criar um novo
if (Test-Path $relatorio) {
    Remove-Item $relatorio
}

# Itera sobre cada usuário na lista de demitidos
$demitidos | ForEach-Object {
    # Atribui os valores de Nome e Grupo do usuário da linha atual do CSV
    $nomeUsuario = $_.Nome
    $grupoUsuario = $_.Grupo

    # Tenta localizar o usuário no Active Directory usando o SamAccountName
    $user = Get-ADUser -Filter {SamAccountName -eq $nomeUsuario} -Properties MemberOf, Enabled

    # Se o usuário for encontrado no AD
    if ($user) {
        # Verifica se a conta do usuário está habilitada
        if ($user.Enabled) {
            # Desativa a conta do usuário no AD
            Disable-ADAccount -Identity $user

            # Remove o usuário de todos os grupos aos quais ele pertence
            $user.MemberOf | ForEach-Object { 
                Remove-ADGroupMember -Identity $_ -Members $user -Confirm:$false 
            }

            # Cria uma entrada de log com os dados do usuário desativado
            $logEntry = [PSCustomObject]@{
                Usuario = $nomeUsuario
                Status = "Desativado"
                Data = Get-Date
                Grupo = $grupoUsuario
            }

            # Exporta a entrada de log para o arquivo de relatório
            $logEntry | Export-Csv -Path $relatorio -Append -NoTypeInformation

            # Exibe uma mensagem informando que o usuário foi desativado e removido dos grupos
            Write-Host "$nomeUsuario foi desativado e removido dos grupos."
        }
        else {
            # Se o usuário já estiver desativado, exibe uma mensagem
            Write-Host "O $nomeUsuario ja estava desativado"
        }
    }
    else {
        # Se o usuário não for encontrado no AD, exibe uma mensagem
        Write-Host " $nomeUsuario nao encontrado no AD"
    }
}

# Exibe uma mensagem indicando que o processo foi concluído, junto com o nome do arquivo de relatório
Write-Host "Processo concluido $relatorio."
