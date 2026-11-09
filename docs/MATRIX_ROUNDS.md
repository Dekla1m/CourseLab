# Преобразование L и раундовые модули

## Реализованные модули

- `l_matrix_comb` вычисляет полное L через 128 постоянных масок. Каждый выходной бит — XOR выбранных входных битов. [l_matrix_comb.v](../CourseLab.srcs/sources_1/l_matrix_comb.v)
- `l_matrix_onecycle` добавляет выходной регистр к комбинационному L. Запуск задаёт `data_input_r`, результат сопровождает `data_output_r`. [l_matrix_onecycle.v](../CourseLab.srcs/experiments/l_matrix_onecycle.v)
- `l_iterative_16cycles` повторно использует один вычислитель R и выдаёт L на 16-м обрабатывающем фронте. Интерфейс использует `start`, `busy` и `done`. [l_iterative_16cycles.v](../CourseLab.srcs/experiments/l_iterative_16cycles.v)
- `kuz_lsx_matrix_comb` выполняет XOR, параллельную подстановку S для 16 байтов и комбинационное L. Старший байт находится в битах `[127:120]`. [kuz_lsx_matrix_comb.v](../CourseLab.srcs/sources_1/kuz_lsx_matrix_comb.v)
- `key_matrix_onecycle` вычисляет `F(Ci, A, B) = (L(S(A XOR Ci)) XOR B, A)`. `data_matrix_onecycle` вычисляет `L(S(data_input XOR Ki))`. Оба используют комбинационный LSX и регистрируют итог. [F](../CourseLab.srcs/sources_1/f_matrix_onecycle.v), [LSX](../CourseLab.srcs/sources_1/lsx_matrix_onecycle.v)

F использует `key_step_enable / key_step_done`, LSX — `data_round_enable / data_round_done`. На фронте с разрешением фиксируется результат. В паузе данные удерживаются, `done` снимается. При непрерывных запусках новый результат доступен каждый такт. Сброс синхронный, активный высокий. Полное расписание шифрования задаёт [Encrypt_TOP](ENCRYPT_TOP.md).

## Проверки

- `tb_L_function` в файле `tb.v` — 7/7 сценариев для однотактного L.
- `tb_iterative` — 8/8 сценариев для 16-тактового L.
- `tb_matrix_round` — 8/8 направленных сценариев F/LSX. По согласованному исключению содержит два независимых DUT. Эталон вычисляет L через арифметику поля независимо от масок RTL. Контрольные значения содержатся в самом TB.

Из корня проекта запускается [check_crypto_tests.ps1](../work/check_crypto_tests.ps1) с `-Test l`, `-Test iterative` или `-Test round`. Журналы: [L](../outputs/unit_tests/l_onecycle/simulation.log), [итерационный L](../outputs/unit_tests/l_iterative/simulation.log), [F/LSX](../outputs/unit_tests/matrix_round/simulation.log).

Число тактов подтверждено функциональной симуляцией. Методика сопоставления ресурсов и частот, а также область применимости отдельных физических экспериментов приведены в [ТЗ и сравнении L](KUZNYECHIK_TZ_AND_L.md).

## Четырёхстадийный раунд

В [kuz_round_fourcycle](../CourseLab.srcs/sources_1/kuz_round_fourcycle.v) между стадиями идут 128 бит.

- ENC выполняет `X → S → R⁸ → R⁸`.
- DEC выполняет `X → R⁻⁸ → R⁻⁸ → S⁻¹`.
- Первый фронт с `data_round_enable=1` фиксирует XOR. Четвёртый фронт, считая фронт XOR, выдаёт `data_round_done=1`. При непрерывной подаче выход обновляется каждый такт.
- Генератор сверяет композицию двух матриц с существующими L и L⁻¹ на всех 128 базисных векторах. Для обратного хода порядок байтов разворачивается до и после той же матрицы. [Генератор](../work/generate_kuz_r8_matrix.py), [маски R⁸](../CourseLab.srcs/sources_1/kuz_r8_matrix_comb.v)

Один тестбенч запущен отдельно с `DECRYPT=0` и `DECRYPT=1`. В каждом режиме прошли три сценария. Проверены значения RFC 7801, два соседних входа с разными ключами, пустой такт и сброс с двумя блоками в работе. [ENC](../outputs/unit_tests/round_fourcycle_enc/simulation.log), [DEC](../outputs/unit_tests/round_fourcycle_dec/simulation.log), [RFC 7801](https://www.rfc-editor.org/rfc/rfc7801.html#section-5.5)

```powershell
& ./work/check_crypto_tests.ps1 -Test round_fourcycle
```

### Отдельный замер на 200 МГц

Прямой раунд в прогоне от 09.11.2026 уложился в 5 нс после трассировки. WNS составил +0,177 нс, WHS +0,047 нс. Следующий замер — обратный раунд.

1. Использовать верхний модуль `test_impl_round_fourcycle`. По умолчанию `DECRYPT=1` выбирает DEC. [Стенд](../CourseLab.srcs/experiments/test_impl_round_fourcycle.v)
2. Для прогона стенда задать входному `clk` период 5,000 нс и полупериод 2,500 нс. Данные и ключ подаются через независимые входные регистры, все выходные биты доступны через выбор 32-битного слова.
3. После трассировки посмотреть внутренние пути `dut`, WNS/WHS и расход LUT/FF для DEC при 200 МГц.

В рабочем `kuz_round_pipeline` установлены девять четырёхстадийных раундов на направление. Стенд одного раунда остаётся в `experiments`.
