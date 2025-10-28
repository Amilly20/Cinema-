*** Settings ***
Documentation    Suite de Testes da API de Reserva de Cinema.
Resource         ../resources/setup.robot           # Configura a URL Base e variáveis
Resource         ../resources/api_keywords.robot    # Importa os ServiceObjects (Ações POST/DELETE)
Library          JSONLibrary                        # Para validação do JSON de resposta
Test Setup       Iniciar Sessão API                 # Garante que a sessão HTTP é criada antes de CADA Test Case

*** Variables ***
# Variáveis de Dados de Teste
${TEST_ASSENTO_ID}      A15
${TEST_SESSAO_ID}       1001 # Sessão de filme existente
${TEST_CPF_CLIENTE}     12345678900 # CPF válido

*** Test Cases ***
C01 - Reserva de Assento Válida (Fluxo Principal)
    [Documentation]    Cenário Positivo: Cria uma reserva com todos os dados corretos.

    Given que a Autenticação é realizada com sucesso
        Log    Token de acesso obtido: ${AUTH_TOKEN}

    When uma nova reserva é criada para o assento "${TEST_ASSENTO_ID}" na sessão "${TEST_SESSAO_ID}"
        ${response}=    Criar Nova Reserva
        ...    ${TEST_ASSENTO_ID}
        ...    ${TEST_SESSAO_ID}
        ...    ${TEST_CPF_CLIENTE}
        
    Then a resposta deve ser de sucesso (201 Created)
        Should Be Equal As Strings    ${response.status_code}    201
        
    And o corpo da resposta deve conter os dados da reserva
        ${body}=    Set Variable    ${response.json()}
        # Validação mais complexa do schema e do conteúdo (Ponto Avaliativo!)
        JSON Should Be Valid For Schema    ${body}    {"type": "object", "required": ["id_reserva", "status"]}
        Should Contain    ${body}    ${TEST_ASSENTO_ID}
        
    And o ID da Reserva deve ser armazenado para testes futuros (DELETE/GET)
        ${ID_RESERVA_C01}=    Get Value From Json    ${body}    $.id_reserva
        Set Suite Variable    ${ID_RESERVA_C01}

C02 - Falha ao Reservar Assento Ocupado (Cenário Negativo)
    [Documentation]    Cenário Negativo: Tenta reservar um assento que já foi reservado (Regra de Negócio).

    Given que a Autenticação é realizada com sucesso
        Log    Token de acesso obtido: ${AUTH_TOKEN}
        # Garante a pré-condição: reserva C01 já foi feita (assento ocupado)
        
    When uma nova tentativa de reserva é feita para o MESMO assento "${TEST_ASSENTO_ID}"
        # Usamos uma nova requisição com os mesmos dados, simulando a concorrência
        ${response}=    Criar Nova Reserva
        ...    ${TEST_ASSENTO_ID}
        ...    ${TEST_SESSAO_ID}
        ...    11122233344 # Novo CPF para simular outro usuário
        
    Then a resposta deve ser de Falha (Conflito 409 ou Bad Request 400)
        # Validação do status de falha (Ponto Avaliativo!)
        Should Be True    ${response.status_code} == 409 or ${response.status_code} == 400
        
    And o corpo da resposta deve indicar que o assento está indisponível
        ${mensagem}=    Get Value From Json    ${response.json()}    $.mensagem
        Should Contain    ${mensagem}[0]    assento indisponível

C07 - Fluxo Completo: Reserva e Cancelamento com Sucesso
    [Documentation]    Cenário Complexo: Testa o ciclo completo de vida de uma reserva.

    Given que a Autenticação é realizada com sucesso
        Log    Preparando para o fluxo de reserva e cancelamento.
        
    When uma nova reserva para o assento "B20" é criada com sucesso
        ${resp_cria}=    Criar Nova Reserva
        ...    B20
        ...    ${TEST_SESSAO_ID}
        ...    55566677788 # CPF fictício
        
        Should Be Equal As Strings    ${resp_cria.status_code}    201
        
        # Uso de Manipulação de Dados (Ponto Avaliativo!)
        ${ID_RESERVA_C07}=    Get Value From Json    ${resp_cria.json()}    $.id_reserva
        Set Test Variable    ${ID_RESERVA_C07}
        
    And a reserva é cancelada usando seu ID
        # Chamo o ServiceObject de DELETE, passando o ID
        ${resp_cancela}=    Cancelar Reserva por ID    ${ID_RESERVA_C07}[0]

    Then a resposta de cancelamento deve ser de sucesso (200 OK)
        Should Be Equal As Strings    ${
