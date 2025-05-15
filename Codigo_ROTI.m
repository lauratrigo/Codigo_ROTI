%bloco 1: inicialização e configuração
clc; %limpa o conteúdo da janela de comando
clear; %remove todas as variáveis do workspace
close all; %fecha todas as figuras abertas

%bloco 2: definição do caminho da pasta
folder_path = 'C:\Users\Virginia\Documents\RotPython';

%bloco 3: identificadores das estações e intervalo de dias
stations = {'Impz', 'Fort', 'Cuib', 'Crat', 'Braz', 'Bomj', 'Recf', 'Uepp', 'Salv', 'Para', 'Vico', 'Smar', 'Riod', 'Poal'}; %stations: um vetor que contém os nomes das estações
days = 12:23; %days: um vetor que determina o intervalo de dias que serão analisados

%bloco 4: definição dos dias sem dados de cada estação
no_data_days.Fort = [17, 22, 23]; %no_data_days.nome_da_estação: estrutura que armazena os dias sem dados de cada estação
no_data_days.Cuib = [13, 14, 18];
no_data_days.Crat = [13, 14, 18, 23];
no_data_days.Salv = [17];

%bloco 5: definição dos limites do eixo y no gráfico 
y_axis_limits = containers.Map(stations, repmat({[0.0, 1.05]}, 1, numel(stations))); %mapa que associa cada estação a um intervalo de valores para o eixo Y, aqui todas as estações tem um intervalo de 0.0 à 1,5

%bloco 6: cria a figura onde os gráficos serão plotados
figure;

%bloco 7: determina o índice do gráfico do meio
middle_plot_index = ceil(length(stations)/2); %calcula o índice do gráfico que ficará no meio da figura, é útil para adicionar rótulos ou legendas específicas no gráfico central, que aqui no caso foi o ROTI

%bloco 8: loop sobre as estações
for s = 1:length(stations) %inicia o loop que percorre todas as estações
    station = stations{s}; %seleciona a estação atual
    all_data = []; %inicializa uma variável par armazenar todos os dados da estação atual

    %bloco 9: loop sobre os dias
    for day = days %inicia um loop que percorre todos os dias definidos, neste caso do dia 12 ao dia 23
        date_str = datetime(2003, 10, day); %cria uma string de data para o dia atual

        %bloco 10: verifica os dias sem dados
        if isfield(no_data_days, station) && ismember(day, no_data_days.(station)) %verifica se a estação atual tem dias sem dados e verifica se o dia atual está na lista de dias sem dados de cada respectiva estação
            %cria um valor NaN para indicar lacunas de dados 
            empty_data = table(date_str, NaN, 'VariableNames', {'Datetime', 'ROTI5m_TECU_min'}); %cria uma tabela com o valor NaN para indicar a falta de dados
            all_data = [all_data; empty_data]; %adiciona os dados vazios à lista de dados da estação
            continue; %pula para o próximo dia
        end

        %bloco 11: leitura dos arquivos de dados
        file_name = sprintf('sorted_sensor_data_%s_%d.txt', station, day); %gera o nome do arquivo de dados para a estação e dia atual
        file_path = fullfile(folder_path, file_name); %concatena o caminho da pasta com o nome do arquivo

        file_info = dir(file_path); %obtém informações sobre o arquivo
        if ~isempty(file_info) && file_info.bytes > 0 %verifica se o arquivo existe e não está vazio
            try
                data = readtable(file_path, 'Delimiter', '\t'); %lê o arquivo de dados como uma tabela
                if any(strcmp(data.Properties.VariableNames, 'Hour_UT')) && any(strcmp(data.Properties.VariableNames, 'ROTI5m_TECU_min')) 
                    data.Datetime = date_str + hours(data.Hour_UT); %converte a hora UTC para um objeto datetime 
                    data.ROTI5m_TECU_min(data.ROTI5m_TECU_min > 1) = NaN; %substituí valores maiores que 1 por NaN
                    all_data = [all_data; data(:, {'Datetime', 'ROTI5m_TECU_min'})]; %adiciona os dados à lista de dados da estação
                else
                    fprintf('Pulando arquivo (colunas ausentes): %s\n', file_name); %printa uma mensagem de erro caso o arquivo esteja ausente, vazio ou corrompido
                end
            catch
                fprintf('Arquivo vazio ou corrompido: %s\n', file_name);
            end
        else
            fprintf('Arquivo n�o existe ou est� vazio: %s\n', file_name);
        end
    end

    %bloco 12: criação dos subplots
    subplot(length(stations), 1, s); %cria um subplot para a estação atual
    hold on; %mantém o gráfico atual para adicionar mais dados
    
    if ~isempty(all_data) 
        plot(all_data.Datetime, all_data.ROTI5m_TECU_min, 'b'); 
        ylim(y_axis_limits(station)); %plota os dados da estação
        legend(station, 'Location', 'northeast'); %adiciona uma legenda com o nome da estação
    end
    
    grid on; %ativa a grade no gráfico
    
    %bloco 13: adição de rótulos e formatação
    if s == middle_plot_index
        text(-0.1, 0.5, 'ROTI (TECU/min)', 'Units', 'normalized', 'HorizontalAlignment', 'center', ...
            'VerticalAlignment', 'middle', 'Rotation', 90, 'FontSize', 12); %adiciona o texto ROTI (TECU/min) no meio do gráfico
    end
    
    if s == length(stations)
        xlabel('Time (Days)', 'FontSize', 12); 
    end
    
    if s < length(stations)
        set(gca, 'XTickLabel', []); %remove todos os rótulos do eixo x dos gráficos que não são o último
end

%bloco 14: formatação final do gráfico
linkaxes(findall(gcf, 'Type', 'axes'), 'x'); %sincroniza os eixos x de todos os subplots
datetick('x', 'mm/dd', 'keeplimits', 'keepticks'); %formata o eixo x para exibir as datas no formado mm/dd

set(gca, 'XTickLabelRotation', 45); %rotaciona os rótulos do eixo x em 45°
set(gcf, 'Position', [100, 100, 1000, 1200]); %ajusta o tamanho e posição da figura