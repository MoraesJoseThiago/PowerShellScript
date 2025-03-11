# Definição do caminho do arquivo com os nomes dos usuários
$arquivo = "nomes.txt"

# Definição da Unidade Organizacional (OU) onde os usuários serão criados
$OU = "OU=Usuarios,DC=dominio,DC=com"

# Definição da senha temporária
$senhaPadrao = "Senha@123"

# Lista dos grupos que serão criados no Active Directory
$gruposAD = "TI", "Comercial", "Financeiro", "Compras", "Produção"

# Criar grupos caso não existam
foreach ($grupo in $gruposAD) {
    if (-not (Get-ADGroup -Filter { Name -eq $grupo })) {
        New-ADGroup -Name $grupo -GroupScope Global -Path "OU=Grupos,$OU" -Description "Grupo de $grupo"
    }
}

# Inicializa contador para distribuir usuários nos grupos
$contador = 0

# Ler cada linha do arquivo e processar os usuários
Get-Content $arquivo | ForEach-Object {
    try {
        # Separar nome do usuário e departamento
        $dados = $_ -split ";"
        $usuarioNome = $dados[0] -replace "_", " "
        $usuarioLogin = ($dados[0] -replace "_", ".").ToLower()
        
        # Distribuir usuário entre os grupos de forma cíclica
        $grupoUsuario = $gruposAD[$contador % $gruposAD.Count]
        $contador++
        
        # Verificar se o usuário já existe antes de criar
        if (-not (Get-ADUser -Filter {SamAccountName -eq $usuarioLogin})) {
            # Criar o usuário no AD
            New-ADUser -Name $usuarioNome -SamAccountName $usuarioLogin -UserPrincipalName "$usuarioLogin@dominio.com" -Path $OU `
                -AccountPassword (ConvertTo-SecureString $senhaPadrao -AsPlainText -Force) -Enabled $true -ChangePasswordAtLogon $true
            
            # Adicionar usuário ao grupo correspondente
            Add-ADGroupMember -Identity $grupoUsuario -Members $usuarioLogin
        }
    }
    catch {
        Write-Host "Erro ao criar usuário: $_"
    }
}

# Exibir mensagem de conclusão
Write-Host "Processo concluído!"
