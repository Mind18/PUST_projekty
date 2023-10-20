import symulacja_obiektu8y_p1.*

% Inicjalizacja

clear;
zad_2_target = 'u'; % 'u' lub 'y'
u_konc = [0.7 1.3 1.1 0.5 1.5]; % Sygnały u(k) użye do odpowiedzi skokowej
k_konc = 400; 
u(1, 1:11) = 0.5; % Sygnał początkowy do zad.1
u(1, 12:k_konc) = 1; % Sygnał końcowy do zad.2
y = zeros(1, k_konc);

% Inicjalizacja danych algorytmu DMC
D = 200; % Horyzont dynamiki D
s = zeros(1, D);
skok_u = 5; % Wybrana odpowiedź skokowa do wyznaczenia wektora s;

% Punkt pracy według funkcji symulacji obiektu
upp = 1;
ypp = 1.7;

%% Realizacja zadania 1 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%1

% Symulacja obiektu
for k=12:k_konc
    y(k) = symulacja_obiektu8y_p1(u(k-10), u(k-11), y(k-1), y(k-2));
end

% Narysowanie wykresu u(k)
figure;
plot(1:k_konc, u);
hold on;
xlabel('k');
ylabel('u(k)');
ylim([0 1.2]);
title('Wykres u(k)');
hold off;
export_fig('./pliki_wynikowe/test_punktu_pracy_u(k).pdf');

% Narysowanie wykresu y(k)
figure;
plot(1:k_konc, y);
hold on;
xlabel('k');
ylabel('y(k)');
title('Wykres y(k)');
hold off;
export_fig('./pliki_wynikowe/test_punktu_pracy_y(k).pdf');

%% Realizacja zadania 2 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% wektory dla przechowywania danych statycznych
u_stat = zeros(1, size(u_konc, 2)+1);
u_stat(1) = upp;
u_stat(2:size(u_konc, 2)+1) = u_konc;
y_stat = zeros(1, size(u_konc, 2)+1);
y_stat(1) = ypp;
% wektory dla przechowywania danych statycznych

% Narysowanie wykresów sygnałów u(k) odp. skokowej
figure;
for i=1:size(u_konc, 2)
    u(1, 1:200) = upp; % U_pp=1
    u(1, 201:k_konc) = u_konc(i);
    plot(1:k_konc, u);
    hold on;
end

% Dodanie informacji do wygenerowanego wykresu
legend_list = strings([1 size(u_konc, 2)]);
xlabel('k');
ylabel('u(k)');
ylim([0.4 1.6]);
title('Wykres u(k)');
for i=1:size(u_konc, 2)
    legend_text = 'u(k)=' + string(u_konc(i));
    legend_list(i) = legend_text;
end
legend(legend_list, 'Location', 'best');
hold off;
export_fig('./pliki_wynikowe/zad2_u(k).pdf');

% Narysowanie wykresów y(k) odp. skokowej
figure;
for i=1:size(u_konc, 2)
    u(1, 1:200) = upp; % U_pp=1
    u(1, 201:k_konc) = u_konc(i);
    for k=12:k_konc
        y(k) = symulacja_obiektu8y_p1(u(k-10), u(k-11), y(k-1), y(k-2));
    end

    if skok_u == i
        for k=1:D
            % Realizacja zadania 3
            s(k) = (y(k+200) - ypp) / (u_konc(skok_u) - upp);
        end
    end

    plot(1:k_konc, y);
    hold on;
  
    y_stat(i+1) = y(k_konc); % zapis danych dla wektora statycznego y
end



% Dodanie informacji do wygenerowanego wykresu
legend_list = strings([1 size(u_konc, 2)]);
xlabel('k');
ylabel('y(k)');
title('Wykres y(k)');
for i=1:size(u_konc, 2)
    legend_text = 'y(k)=' + string(y_stat(i+1));
    legend_list(i) = legend_text;
end
legend(legend_list, 'Location', 'southeast');
hold off;
export_fig('./pliki_wynikowe/zad2_y(k).pdf');

% ch-ka stat%
% sortowanie i rysowanie danych
figure;
[u_stat, sortIndex] = sort(u_stat);
y_stat = y_stat(sortIndex);

plot(u_stat, y_stat);
hold on;
plot(u_stat, y_stat, '.', 'MarkerSize',12);
legend("Interpolacja danych statycznych", "Dane statyczne", 'Location', 'southeast');
k_stat = rdivide(y_stat, u_stat);

xlabel('u');
ylabel('y(u)');
title('Dane statyczne y(u)');
hold off;
export_fig('./pliki_wynikowe/zad2_y(u)_stat.pdf');

% Narysowanie odpowiedzi skokowej
figure;
plot(1:200, s);
title_name = "Odpowiedź skokowa układu dla u_{konc}=" + ...
    string(u_konc(skok_u));
title(title_name);
xlabel('k');
ylabel('y(k)');
export_fig('./pliki_wynikowe/odpowiedź_skokowa.pdf');
