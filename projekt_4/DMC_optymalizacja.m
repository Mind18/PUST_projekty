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
e_tmp = 0;
e_dmc(1:k_konc) = 0;

% Optymalizacja parametrów
x0 = [psi(1) psi(2) psi(3) lambda(1) lambda(2) lambda(3) lambda(4)];
A = [1, 1, 1, 0.1, 0.1, 1, 1];
b = 50;
lb = [0, 0, 0, 0, 0, 0, 0];
ub = [10, 10, 10, 50, 25, 10, 10];
f = @(dmc_param)DMC_SE(dmc_param, S);
% dmc_params = fmincon(f, x0, A, b, [], [], lb, ub);
% 
% psi = [dmc_params(1) dmc_params(2) dmc_params(3)];
% lambda = [dmc_params(4) dmc_params(5) dmc_params(6) dmc_params(7)];

psi = [9.4887 9.4746 9.6204];
lambda = [0.976 1.5806 7.4216 2.1519];

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

% Wyznaczenie macierzy K_e
K_e = zeros(wejscia, wyjscia);
for i=0:N-1
    K_e = K_e + K(1:wejscia, 1+i*wyjscia:(i+1)*wyjscia);
end

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
    for j=1:D-1
        K_j_inc = K(1:wejscia, :)*M_p(:, 1+(j-1)*wejscia:j*wejscia);
        K_j = K_j + K_j_inc*U_p(1+(j-1)*wejscia:j*wejscia);
    end
    delta_U = K_e*e(:, k) - K_j;
    % Ograniczenia zmiany sterowania
    for n_u=1:wejscia
        if delta_U(n_u) < du_min
            delta_U(n_u) = du_min;
        end
        if delta_U(n_u) > du_max
            delta_U(n_u) = du_max;
        end
    end
    % Zapamiętanie zmiany sterowania do kolejnych iteracji
    for n=D-1:-1:2
        U_p(1+(n-1)*wejscia:n*wejscia, 1) = ...
            U_p(1+(n-2)*wejscia:(n-1)*wejscia, 1);
    end
    U_p(1:wejscia) = delta_U;
    % Dokonanie zmiany wartości sterowania
    u(:, k) = u(:, k-1) + delta_U;
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
    plot(1:k_konc, u(i, :));
end
title('u(k) - DMC optymlaizacja');
legend('u_1', 'u_2', 'u_3', 'u_4');
hold off;
export_fig("./pliki_wynikowe/dmc_optymalizacja_u.pdf")

figure;
hold on;
for i=1:wyjscia
    plot(1:k_konc, y(i, :));
    plot(1:k_konc, yzad(i, 1:k_konc));
end
title('y(k) - DMC optymalizacja E=' + string(E));
legend('y_1', 'y^{zad}_1', 'y_2', 'y^{zad}_2', 'y_3', 'y^{zad}_3');
hold off;
export_fig("./pliki_wynikowe/dmc_optymalizacja_y.pdf")