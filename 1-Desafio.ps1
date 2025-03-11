# Caminho para o arquivo CSV contendo os dados dos usuários
$arquivoUsuarios = "C:\Caminho\Para\Seu\Arquivo\usuarios.csv"

# Definir senha padrão para todos os usuários
$senhaPadrao = "Senha@123"

# Definir o domínio para os UPN (User Principal Name)
$dominio = "dominio.com"

# Importar os usuários do arquivo CSV
$usuarios = Import-Csv -Path $arquivoUsuarios -Delimiter ";"

# Exibir os usuários encontrados no arquivo
$usuarios | ForEach-Object { Write-Host "Usuário encontrado: $($_.Nome), Grupo: $($_.Grupo)" }

# Processar cada usuário
foreach ($usuario in $usuarios) {
    $nomeDeConta = $usuario.Nome
    $UPN = "$nomeDeConta@$dominio"
    $grupo = $usuario.Grupo

    # Verificar se o usuário já existe no Active Directory
    if (-not (Get-ADUser -Filter {SamAccountName -eq $nomeDeConta} -ErrorAction SilentlyContinue)) {
        # Criar o usuário no AD
        New-ADUser -Name $usuario.Nome `
                   -SamAccountName $nomeDeConta `
                   -UserPrincipalName $UPN `
                   -AccountPassword (ConvertTo-SecureString $senhaPadrao -AsPlainText -Force) `
                   -Enabled $true `
                   -ChangePasswordAtLogon $true `
                   -Path "CN=Users,DC=dominio,DC=com"
        Write-Host "Usuário $nomeDeConta criado."
    } else {
        Write-Host "Usuário $nomeDeConta já existe. Pulando criação..."
    }

    # Verificar se o grupo já existe no AD
    if (-not (Get-ADGroup -Filter {Name -eq $grupo} -ErrorAction SilentlyContinue)) {
        # Criar o grupo no AD
        New-ADGroup -Name $grupo `
                    -GroupScope Global `
                    -GroupCategory Security `
                    -Path "CN=Users,DC=dominio,DC=com"
        Write-Host "Grupo $grupo criado."
    } else {
        Write-Host "Grupo $grupo já existe."
    }

    # Adicionar o usuário ao grupo
    Add-ADGroupMember -Identity $grupo -Members $nomeDeConta
    Write-Host "Usuário $nomeDeConta adicionado ao grupo $grupo."
}

# Exibir mensagem de conclusão
Write-Host "Processo de criação de usuários e grupos concluído!"
