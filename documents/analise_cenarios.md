# Cenários de Teste Funcionais para API de Reserva de Cinema

## Foco: Módulo de Reserva (POST /reservas, DELETE /reservas/{id})

| Tipo de Cenário | ID | Objetivo | Condições (Dado que) | Ação (Quando) | Resultado Esperado (Então) | Cobertura |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **POSITIVO (Fluxo Principal)** | C01 | Criar uma reserva válida com sucesso. | Assento disponível, dados do cliente e token válidos. | Enviar requisição `POST /reservas` com os dados completos. | Status **201** (Created) e retorno dos dados da reserva (ID). | Funcional |
| **NEGATIVO 1** | C02 | Tentar reservar com assento já ocupado. | Assento já está previamente reservado/vendido. | Enviar requisição `POST /reservas` para o assento ocupado. | Status **409** (Conflict) ou **400** (Bad Request) com mensagem de erro clara. | Concorrência |
| **NEGATIVO 2** | C03 | Tentar reservar sem autenticação. | Nenhum `Authorization Header` (Token) é enviado. | Enviar requisição `POST /reservas` sem o token de acesso. | Status **401** (Unauthorized) (Não Autorizado). | Segurança |
| **NEGATIVO 3** | C04 | Tentar reservar com dados obrigatórios faltando. | O `payload` da requisição está sem o `session_id` ou `cpf`. | Enviar requisição `POST /reservas` com o campo essencial faltando. | Status **400** (Bad Request) e mensagem de erro de validação. | Validação de Dados |
| **BORDA 1** | C05 | Reservar o último assento disponível. | A sessão tem apenas 1 assento restante (Situação limite). | Enviar requisição `POST /reservas` para reservar esse único assento. | Status **201**. A próxima consulta deve mostrar 0 assentos restantes. | Cobertura Borda |
| **BORDA 2** | C06 | Tentar reservar após o horário limite. | A hora atual é posterior ao limite de tempo para fazer a reserva. | Enviar requisição `POST /reservas` para a sessão. | Status **400** com mensagem de "Reserva Expirada/Encerrada". | Regra de Negócio |
| **FLUXO COMPLEXO** | C07 | Reserva de Sucesso + Cancelamento. | Reserva C01 feita com sucesso e dentro do prazo de cancelamento. | 1. Criar reserva (C01). 2. Consultar. 3. Enviar `DELETE /reservas/{id}`. | Status **200** (OK) no Cancelamento, e o assento deve voltar a ficar disponível. | Cenário Complexo |
