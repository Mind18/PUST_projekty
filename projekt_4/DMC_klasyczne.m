import symulacja_obiektu8y_p4.*

% Alokacja wektora sterowań w odpowiednim rozmiarze
u = zeros(wejscia, k_konc);

% Inicjacja macierzy trajektorii zadanej
yzad = zeros(wyjscia, k_konc);
y = zeros(wyjscia, k_konc);

% Inicjacja wektora U_p
U_p = zeros(wejscia*(D-1), 1);
delta_U = zeros(wejscia, 1);

e = zeros(wyjscia, k_konc);
e_1 = zeros(wyjscia*N, 1); % Wektor uchybu wykorzystywany w obliczeniach
e_tmp = 0;
e_dmc(1:k_konc) = 0;

% Generowanie macierzy wagowych
Psi = zeros(wyjscia*N, wyjscia*N);
psi_inputed = 1;
for i=1:wyjscia*N
    Psi(i, i) = psi(psi_inputed);
    if psi_inputed == wyjscia
        psi_inputed = 1;
    else
        psi_inputed = psi_inputed + 1;
    end
end

Lambda = zeros(wejscia*N_u, wejscia*N_u);
lambda_inputed = 1;
for i=1:wejscia*N_u
    Lambda(i, i) = lambda(lambda_inputed);
    if lambda_inputed == wyjscia
        lambda_inputed = 1;
    else
        lambda_inputed = lambda_inputed + 1;
    end
end

M_cell = cell(N, N_u);
for j=1:N_u
    for i=1:N
        M_cell{i, j} = zeros(wyjscia, wejscia);
    end
end

for n=1:N_u
    for m=n:N
        M_cell{m, n} = S{m-n+1};
    end
end
M = cell2mat(M_cell);

M_p_cell = cell(N, (D-1));
for j=1:(D-1)
    for i=1:N
        M_p_cell{i, j} = zeros(wyjscia, wejscia);
    end
end

for j=1:(D-1)
    for i=1:N
        if j+i > D
            p = D;
        else
            p = j+i;
        end
        M_p_cell{i, j} = S{p} - S{j};
    end
end
M_p = cell2mat(M_p_cell);

for i=1:wyjscia
    e(i, 1:k_konc) = 0;
    y(i, :) = zeros(k_konc, 1);

    % Generacja zmiennej trajektori
    yzad(i, 1:9)=ypp;
    yzad(i, 10:500)=Y_zad{i}(1);
    yzad(i, 501:1000)=Y_zad{i}(2);
    yzad(i, 1001:1500)=Y_zad{i}(3);
    yzad(i, 1501:k_konc)=Y_zad{i}(4);
end

% Wyznaczenie wektora współczynników K
K = ((M'*Psi*M+Lambda)^(-1))*M'*Psi;

for k=10:k_konc
    % symulacja obiektu
    [y(1, k), y(2, k), y(3, k)] = symulacja_obiektu8y_p4(u(1, k-1), ...
        u(1, k-2), u(1, k-3), u(1, k-4), u(2, k-1), u(2, k-2), u(2, k-3), ...
        u(2, k-4), u(3, k-1), u(3, k-2), u(3, k-3), u(3, k-4), u(4, k-1), ...
        u(4, k-2), u(4, k-3), u(4, k-4), y(1, k-1), y(1, k-2), y(1, k-3), ...
        y(1, k-4), y(2, k-1), y(2, k-2), y(2, k-3), y(2, k-4), y(3, k-1), ...
        y(3, k-2), y(3, k-3), y(3, k-4));
    
    % Wyznaczenie zmiany sterowania
    K_j = zeros(wejscia, 1);
    e(:, k)=yzad(1:wyjscia, k) - y(1:wyjscia, k); % Uchyb regulacji
    e_1 = e(mod(0:wyjscia*N-1, wyjscia)+1, k);
    delta_U = K*(e_1-M_p*U_p);
    delta_u = delta_U(1:wejscia);
    % Ograniczenia zmiany sterowania
    for n_u=1:wejscia
        if delta_u(n_u) < du_min
            delta_u(n_u) = du_min;
        end
        if delta_u(n_u) > du_max
            delta_u(n_u) = du_max;
        end
    end
    % Zapamiętanie zmiany sterowania do kolejnych iteracji
    for n=D-1:-1:2
        U_p(1+(n-1)*wejscia:n*wejscia, 1) = ...
            U_p(1+(n-2)*wejscia:(n-1)*wejscia, 1);
    end
    U_p(1:wejscia) = delta_u;
    % Dokonanie zmiany wartości sterowania
    u(:, k) = u(:, k-1) + delta_u;
    % Ograniczenie wartości sterowania
    for n_u=1:wejscia
        if u(n_u, k) < u_min
            u(n_u, k) = u_min;
            U_p(n_u) = u(n_u, k)-u(n_u, k-1);
        end
        if u(n_u, k) > u_max
            u(n_u, k) = u_max;
            U_p(n_u) = u(n_u, k)-u(n_u, k-1);
        end
    end
    
    for i=1:wyjscia
        e_tmp = e_tmp + (yzad(i, k) - y(i, k))^2;
    end
    e_dmc(k) = e_dmc(k-1) + e_tmp;
    e_tmp = 0;
end

E = e_dmc(k_konc); % Zapamiętanie błędu średniokwadratowego E symulacji

figure;
hold on;
for i=1:wejscia
    plot(1:k_konc, u(i, :),'LineWidth', linia);
end
title(['u(k) - DMC klasyczny ' parametersDMC]);
legend('u_1', 'u_2', 'u_3', 'u_4', 'Location', 'Best');
hold off;
export_fig("./pliki_wynikowe/"+string(wykres)+"DMCKLAS_uzad.pdf")

figure;
hold on;
for i=1:wyjscia
    plot(1:k_konc, y(i, :),'LineWidth', linia);
    plot(1:k_konc, yzad(i, 1:k_konc),'LineWidth', linia);
end
title(['y(k) - DMC klasyczny E=' string(E) ' ' parametersDMC]);
legend('y_1', 'y^{zad}_1', 'y_2', 'y^{zad}_2', 'y_3', 'y^{zad}_3', 'Location', 'Best');
hold off;
export_fig("./pliki_wynikowe/"+string(wykres)+"DMCKLAS_yzad.pdf")
    