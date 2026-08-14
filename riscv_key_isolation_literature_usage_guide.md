# Как использовать базу литературы для поиска научного пробела и темы статьи

Инструкция пересмотрена 2026-08-05. Состояние базы — 2026-08-04. В ней находится 180 отобранных источников, 40 источников предварительного аналитического ядра и 96 привязок «тезис → источник → точное место». Дополнительно проверены все 37 загруженных PDF; 10 из них входят в `Core_40`.

## 1. Назначение базы и границы работы

База передаётся научному сотруднику не для написания статьи по заранее утверждённой теме. Её назначение — дать структурированный корпус литературы, на основании которого сотрудник должен самостоятельно:

- разобраться в современном состоянии исследований по аппаратной безопасности RISC-V, криптографических микроконтроллеров и доверенных вычислительных компонентов;
- выделить основные направления, используемые модели угроз, механизмы защиты и способы экспериментальной проверки;
- установить, какие задачи уже решены, какие решения противоречат друг другу или плохо сопоставимы, а какие вопросы остаются недостаточно исследованными;
- сформулировать научный пробел, проверить его новизну дополнительным поиском и предложить реалистичную тему статьи.

Первоначальная тема «Изоляция ключей и доверенного кода в RISC-V криптоконтроллерах» больше не является обязательной. Она использовалась для первичного отбора и классификации литературы. Сотрудник может сузить, расширить или изменить направление, если вывод подтверждается анализом источников и остаётся в предметной области проекта.

Границы исходного корпуса охватывают:

- PMP/ePMP, privilege modes, enclaves и security monitors;
- bus firewalls, DMA/IOPMP, interrupt и peripheral isolation;
- аппаратные корни доверия, secure/measured boot и attestation;
- key path, secure storage, защищённую и scrambled memory;
- lifecycle control, debug/JTAG lockdown, shadow registers и zeroization;
- fault injection, remanence, memory-aliasing и другие атаки на границы изоляции;
- формальную верификацию, information-flow analysis и аппаратную security assurance;
- архитектуры RISC-V TEE, OpenTitan и сопоставимые решения других платформ.

Это широкая стартовая область, а не готовая формулировка статьи. Отсутствие работы в этой базе само по себе не доказывает наличие научного пробела.

Назначение листов:

- `Core_40` — предварительная выборка для погружения в предметную область. Сотрудник должен критически пересмотреть её после чтения.
- `Final_200` — основной корпус для картирования поля и формирования будущего списка литературы. Не следует автоматически включать все записи в статью.
- `Evidence_Matrix` — исходная матрица механизмов, угроз, активов, методов проверки и ограничений. Её следует расширять собственными наблюдениями.
- `Article_Mapping` — пример привязки тезисов к источникам, созданный под первоначальную тему. Это навигатор, но не обязательный план будущей статьи.
- `URL_Audit` — сведения о DOI/URL и локальных файлах. `VERIFIED_LOCAL_PDF` означает, что полный текст уже получен и проверен.
- `Audit` — ограничения базы, исправления метаданных и контроль качества.

## 2. Задание научному сотруднику

### 2.1 Этап 1 — первичное погружение

1. Прочитать несколько обзорных работ из начала `Final_200`, чтобы восстановить терминологию и карту исследовательских направлений.
2. Изучить нормативные материалы RISC-V и OpenTitan из `Core_40`: они задают фактическое поведение PMP/ePMP, IOPMP, lifecycle, OTP, key manager, shadow registers и других механизмов.
3. Прочитать стартовое ядро из раздела 3 этой инструкции. Для центральных работ изучать не только отмеченные страницы, но также модель угроз, архитектуру, методику оценки, результаты и limitations.
4. Составить собственный словарь понятий и предварительную карту: `актив → нарушитель → поверхность атаки → механизм защиты → доверенная база → способ проверки`.

### 2.2 Этап 2 — картирование существующих работ

Разделить литературу на смысловые кластеры. Для каждой существенной работы зафиксировать:

- какую проблему решают авторы и почему она важна;
- какой актив защищается: ключи, код, данные, конфигурация, состояние загрузки, отладочный интерфейс;
- кто считается нарушителем и какие возможности ему предоставлены;
- какие компоненты входят в trusted computing base;
- где проходит граница изоляции: CPU, memory controller, bus, DMA, peripheral, debug или lifecycle;
- является работа архитектурой, реализацией, атакой, формальной моделью, обзором либо спецификацией;
- на какой платформе выполнена проверка: simulation, FPGA, ASIC, RTL, formal model или реальный чип;
- какие метрики и результаты сообщаются;
- какие ограничения, допущения и нерешённые вопросы прямо признают авторы;
- какие важные свойства вообще не проверялись.

Необходимо отличать выводы авторов от собственного синтеза. Обзор подходит для терминологии и структуры поля; численные результаты, свойства безопасности и сравнение накладных расходов нужно подтверждать первичными работами.

### 2.3 Этап 3 — поиск научного пробела

Искать не просто «мало статей», а содержательный разрыв, например:

- механизм защищает CPU-доступ, но не учитывает DMA, peripheral masters или shared interconnect;
- заявленная изоляция проверена функционально, но не формально или не против активного нарушителя;
- решение показано на FPGA, но отсутствует оценка ASIC/PPA или применимости к микроконтроллеру;
- отдельные механизмы исследованы, но их композиция создаёт непроверенную сквозную границу;
- требования спецификации не совпадают с реальными предположениями реализации;
- атака показывает обход распространённого механизма, а существующие контрмеры неполны либо слишком дороги;
- работа защищает секрет в нормальном режиме, но не рассматривает reset, debug, lifecycle transition, fault response или remanence;
- разные исследования используют несовместимые модели угроз и метрики, из-за чего отсутствует корректное сравнение;
- отсутствуют воспроизводимые реализации, тесты, benchmarks или открытая методика проверки.

Каждый предполагаемый пробел проверить по формуле:

`что уже известно → чего конкретно не хватает → почему это существенно → как это можно исследовать → какой проверяемый результат даст статья`.

Нельзя объявлять пробел только потому, что нужная работа не встретилась среди 180 записей. После появления кандидата обязателен отдельный поиск по Scopus, Web of Science, IEEE Xplore, ACM Digital Library, Springer, ScienceDirect, USENIX, IACR, Google Scholar и цитирующим работам. Нужно использовать поиск назад по библиографии и вперёд по цитированиям.

### 2.4 Этап 4 — формулирование вариантов темы

Подготовить минимум три, желательно пять вариантов. Для каждого указать:

| Поле | Что должно быть сформулировано |
|---|---|
| Рабочее название | Узкая и проверяемая формулировка, без чрезмерно общего обещания |
| Объект исследования | Конкретная архитектура, механизм, граница или класс атак |
| Научный вопрос | На какой вопрос должна ответить статья |
| Существующие решения | 5–10 наиболее близких первичных работ |
| Предполагаемый пробел | Чего нет в существующей литературе и чем это подтверждается |
| Возможный вклад | Модель, архитектура, метод верификации, эксперимент, benchmark, taxonomy или сравнительное исследование |
| Метод проверки | Формальная модель, RTL/FPGA-прототип, simulation, анализ спецификаций, экспериментальная атака и т. п. |
| Доступные ресурсы | Код, IP-блоки, FPGA, инструменты, данные, компетенции и сроки |
| Основные риски | Возможный аналог, отсутствие платформы, слишком широкий scope, невозможность воспроизвести результаты |
| Предварительная оценка | Новизна, значимость, выполнимость и соответствие проекту |

### 2.5 Обязательный результат работы

Научный сотрудник должен передать:

1. Краткую аналитическую записку о структуре предметной области.
2. Собственную сравнительную матрицу основных работ и механизмов.
3. Список из 3–5 возможных научных пробелов с подтверждающими источниками.
4. Таблицу вариантов темы по форме из раздела 2.4.
5. Рекомендованную тему с исследовательским вопросом, предполагаемым вкладом и методом проверки.
6. Рабочую выборку примерно из 30–50 источников, действительно необходимых для выбранной темы.
7. Расширенный библиографический пул до 100–200 позиций только после окончательного выбора темы и дополнительного поиска.

Предложение темы считается обоснованным, если ближайшие аналоги найдены и рассмотрены, отличие сформулировано одним-двумя точными предложениями, вклад можно проверить, а доступные ресурсы позволяют выполнить работу.

## 3. Стартовое ядро для первого чтения

Начать рекомендуется с этих 18 позиций. Они дают нормативную основу и первичное представление о CPU/PMP, DMA/IOPMP, ключевом пути, debug, zeroization и атаках. Это стартовая выборка, а не перечень обязательных ссылок будущей статьи: после определения пробела состав ядра должен быть пересмотрен.

| Core_ID | Final_ID | Источник | Зачем читать | URL |
|---|---|---|---|---|
| C001 | F0106 | OpenTitan Key Manager | Ключевой путь, аппаратный sideload, состояния ключей и очистка. | https://opentitan.org/earlgrey_1.0.0/book/hw/ip/keymgr/index.html |
| C002 | F0177 | OpenTitan Lifecycle Controller — Theory of Operation | Политика жизненного цикла, блокировка debug/test и необратимые переходы. | https://opentitan.org/book/hw/ip/lc_ctrl/doc/theory_of_operation.html |
| C003 | F0176 | OpenTitan OTP Controller — Theory of Operation | Корень доверия, OTP, секреты устройства и аппаратные разделы. | https://opentitan.org/book/hw/ip/otp_ctrl/doc/theory_of_operation.html |
| C006 | F0046 | RISC-V Privileged Architecture — Machine-Level ISA / Physical Memory Protection | Нормативная семантика privilege modes и PMP. | https://docs.riscv.org/reference/isa/v20260120/priv/machine.html |
| C007 | F0060 | Smepmp Extension, Version 1.0 | Усиленная политика PMP/ePMP и locked rules. | https://docs.riscv.org/reference/isa/v20260120/priv/smepmp.html |
| C008 | F0093 | RISC-V IOPMP Architecture Specification | Изоляция DMA и других bus masters; использовать как развивающуюся спецификацию. | https://github.com/riscv-non-isa/riscv-iopmp |
| C010 | F0027 | SPEAR-V: Secure and Practical Enclave Architecture for RISC-V | Практическая архитектура RISC-V enclave и компромиссы реализации. | https://doi.org/10.1145/3579856.3595784 |
| C016 | F0012 | Keystone | Базовая RISC-V TEE-архитектура и роль security monitor. | https://doi.org/10.1145/3342195.3387532 |
| C017 | F0015 | Towards Designing a Secure RISC-V System-on-Chip: ITUS | Системная архитектура защищённого RISC-V SoC. | https://doi.org/10.1007/s41635-020-00108-8 |
| C023 | F0069 | Verifying RISC-V Physical Memory Protection | Формальная проверка PMP; препринт, поэтому проверить опубликованную версию. | https://doi.org/10.48550/arxiv.2211.02179 |
| C025 | F0180 | OpenTitan Access Range Check | Проверка диапазонов адресов и аппаратная граница доступа. | https://opentitan.org/book/hw/top_darjeeling/ip_autogen/ac_range_check/index.html |
| C030 | F0125 | Security Verification of the OpenTitan Hardware Root of Trust | Методы и границы верификации аппаратного корня доверия. | https://doi.org/10.1109/msec.2023.3251954 |
| C033 | F0091 | Aker: A Design and Verification Framework for Safe and Secure SoC Access Control | Проектирование и проверка SoC access control/bus firewall. | https://doi.org/10.1109/iccad51958.2021.9643538 |
| C034 | F0094 | Enhancing configuration flexibility in an Open-Source RISC-V IOPMP IP | Практическая реализация IOPMP; вручную уточнить тип и площадку. | https://hdl.handle.net/1822/101184 |
| C035 | F0011 | Physical Memory Please: Practical Memory-Aliasing Attacks on RISC-V PMP | Реальная граница защиты PMP и требования к проверке адресных алиасов. | https://doi.org/10.46586/uasc.2026.008 |
| C038 | F0077 | A Secure JTAG Wrapper for SoC Testing and Debugging | Защита отладочного и тестового интерфейса. | https://doi.org/10.1109/access.2022.3164712 |
| C039 | F0107 | SRAM has no chill: exploiting power domain separation to steal on-chip secrets | Реманентность SRAM и последствия неполной очистки питания. | https://doi.org/10.1145/3503222.3507710 |
| C040 | F0019 | Bypassing Isolated Execution on RISC-V using Side-Channel-Assisted Fault-Injection and Its Countermeasure | Fault-injection как проверка границ изоляции. | https://doi.org/10.46586/tches.v2022.i1.28-68 |

Официальные материалы RISC-V и OpenTitan не следует называть рецензируемыми статьями. Они нужны как нормативная и проектная основа. Например, IOPMP определяет контроль доступов, выдаваемых bus masters, а OpenTitan Key Manager документирует аппаратное получение ключей, sideload и очистку при ошибочных состояниях.

## 4. Предварительное аналитическое ядро Core_40

### Normative / foundational

| Core_ID | Final_ID | Балл | Название | Раздел статьи | Локальный PDF | URL |
|---|---|---:|---|---|---|---|
| C001 | F0106 | 10 | OpenTitan Key Manager | 6. Key path, secure memory and trusted-code storage | нет | https://opentitan.org/earlgrey_1.0.0/book/hw/ip/keymgr/index.html |
| C002 | F0177 | 10 | OpenTitan Lifecycle Controller — Theory of Operation | 10. Reference isolation model and design trade-offs | нет | https://opentitan.org/book/hw/ip/lc_ctrl/doc/theory_of_operation.html |
| C003 | F0176 | 10 | OpenTitan OTP Controller — Theory of Operation | 10. Reference isolation model and design trade-offs | нет | https://opentitan.org/book/hw/ip/otp_ctrl/doc/theory_of_operation.html |
| C004 | F0173 | 10 | OpenTitan Register Tool — Shadowed Registers | 9. Boundary attacks, assurance and formal verification | нет | https://opentitan.org/book/util/reggen/index.html |
| C005 | F0179 | 10 | OpenTitan Security Documentation | 10. Reference isolation model and design trade-offs | нет | https://opentitan.org/book/doc/security/ |
| C006 | F0046 | 10 | RISC-V Privileged Architecture — Machine-Level ISA / Physical Memory Protection | 4. CPU isolation: PMP/ePMP, privilege modes and enclaves | нет | https://docs.riscv.org/reference/isa/v20260120/priv/machine.html |
| C007 | F0060 | 9 | Smepmp Extension, Version 1.0 | 4. CPU isolation: PMP/ePMP, privilege modes and enclaves | нет | https://docs.riscv.org/reference/isa/v20260120/priv/smepmp.html |
| C008 | F0093 | 9 | RISC-V IOPMP Architecture Specification | 5. Bus, DMA, interrupt and peripheral isolation | нет | https://github.com/riscv-non-isa/riscv-iopmp |

### RISC-V architecture / TEE

| Core_ID | Final_ID | Балл | Название | Раздел статьи | Локальный PDF | URL |
|---|---|---:|---|---|---|---|
| C009 | F0017 | 10 | A Trusted Execution Environment RISC-V System-on-Chip Compatible with Transport Layer Security 1.3 | 4. CPU isolation: PMP/ePMP, privilege modes and enclaves | да, 24 стр.; Local PDF: architecture/root-of-trust contribution p. 3; §5 Secured Boot Flow pp. 11–13; §6 Experimental Results pp. 14–18; §6.4 Security Analysis p. 18; §6.5 comparison pp. 19–20. | https://doi.org/10.3390/electronics13132508 |
| C010 | F0027 | 10 | SPEAR-V: Secure and Practical Enclave Architecture for RISC-V | 4. CPU isolation: PMP/ePMP, privilege modes and enclaves | да, 12 стр.; Local PDF: §3 Threat Model p. 2; §4 Design Overview pp. 2–4; §5 Hardware Design pp. 4–6; §6 Software Design pp. 6–8; §7 Security Analysis p. 8. | https://doi.org/10.1145/3579856.3595784 |
| C011 | F0016 | 10 | DITES: A Lightweight and Flexible Dual-Core Isolated Trusted Execution SoC Based on RISC-V | 4. CPU isolation: PMP/ePMP, privilege modes and enclaves | да, 18 стр.; Local PDF: §3.2 SoC Architecture p. 4; §3.3 Secure Hierarchical Bus p. 5; §3.5.1 IOPMP p. 8; §3.5.4 Confidential Access Policy p. 10; §3.6 Secure Boot pp. 10–11; §4 FPGA/ASIC evaluation pp. 11–15. | https://doi.org/10.3390/s22165981 |
| C012 | F0028 | 10 | uTango: An Open-Source TEE for IoT Devices | 4. CPU isolation: PMP/ePMP, privilege modes and enclaves | нет | https://doi.org/10.1109/access.2022.3152781 |
| C013 | F0013 | 10 | HECTOR-V: A Heterogeneous CPU Architecture for a Secure RISC-V Execution Environment | 4. CPU isolation: PMP/ePMP, privilege modes and enclaves | да, 13 стр.; Local PDF: §3 Threat Model p. 3; §4 Design pp. 3–6 (trusted I/O and security monitor); §5 Implementation pp. 6–9; §6.1 Secure Boot p. 9; §7 Security Discussion p. 10. | https://doi.org/10.1145/3433210.3453112 |
| C014 | F0041 | 10 | In Hardware We Trust? From TPM to Enclave Computing on RISC-V | 4. CPU isolation: PMP/ePMP, privilege modes and enclaves | нет | https://doi.org/10.1109/vlsi-soc53125.2021.9606968 |
| C015 | F0068 | 10 | Memory Encryption Support for an FPGA-based RISC-V Implementation | 4. CPU isolation: PMP/ePMP, privilege modes and enclaves | нет | https://doi.org/10.1109/dtis53253.2021.9505064 |
| C016 | F0012 | 10 | Keystone | 4. CPU isolation: PMP/ePMP, privilege modes and enclaves | да, 16 стр.; Local PDF: §3 “Keystone Overview” pp. 4–5; §4.1 “Memory Isolation” pp. 5–6; §6 “Security Analysis” pp. 9–10; §7 “Evaluation” pp. 10–12. | https://doi.org/10.1145/3342195.3387532 |
| C017 | F0015 | 10 | Towards Designing a Secure RISC-V System-on-Chip: ITUS | 4. CPU isolation: PMP/ePMP, privilege modes and enclaves | нет | https://doi.org/10.1007/s41635-020-00108-8 |
| C018 | F0056 | 9 | Dorami: Privilege Separating Security Monitor on RISC-V TEEs | 4. CPU isolation: PMP/ePMP, privilege modes and enclaves | нет | https://www.usenix.org/conference/usenixsecurity25/presentation/kuhne |
| C019 | F0006 | 9 | A Survey on RISC-V Security: Hardware and Architecture | 1. Introduction and scope; 2. Review taxonomy; 3. Threat model, protected assets and trust boundaries | нет | https://doi.org/10.48550/arxiv.2107.04175 |
| C020 | F0050 | 9 | CURE: A Security Architecture with CUstomizable and Resilient Enclaves | 4. CPU isolation: PMP/ePMP, privilege modes and enclaves | нет | https://www.usenix.org/conference/usenixsecurity21/presentation/bahmani |
| C021 | F0031 | 9 | TIMBER-V: Tag-Isolated Memory Bringing Fine-grained Enclaves to RISC-V | 4. CPU isolation: PMP/ePMP, privilege modes and enclaves | нет | https://doi.org/10.14722/ndss.2019.23068 |
| C022 | F0001 | 8 | A Survey of RISC-V Secure Enclaves and Trusted Execution Environments | 1. Introduction and scope; 2. Review taxonomy; 3. Threat model, protected assets and trust boundaries | да, 35 стр.; Local PDF: §2.2 “RISC-V Security Landscape” p. 3; §3 survey of RISC-V TEEs pp. 4–19; §4.1 design trade-offs p. 20; §4.3 secure I/O p. 21; §4.12 memory-isolation grouping p. 27. | https://doi.org/10.3390/electronics14214171 |
| C023 | F0069 | 8 | Verifying RISC-V Physical Memory Protection | 4. CPU isolation: PMP/ePMP, privilege modes and enclaves | нет | https://doi.org/10.48550/arxiv.2211.02179 |
| C024 | F0097 | 7 | An open-source trusted execution environment for resource-constrained RISC-V MCUs | 5. Bus, DMA, interrupt and peripheral isolation | нет | https://riscv-europe.org/summit/2025/media/proceedings/2025-05-14-RISC-V-Summit-Europe-P3.2.04-CUNHA-abstract.pdf |

### SoC / DMA / verification

| Core_ID | Final_ID | Балл | Название | Раздел статьи | Локальный PDF | URL |
|---|---|---:|---|---|---|---|
| C025 | F0180 | 10 | OpenTitan Access Range Check | 10. Reference isolation model and design trade-offs | нет | https://opentitan.org/book/hw/top_darjeeling/ip_autogen/ac_range_check/index.html |
| C026 | F0126 | 10 | BASTION: A Framework for Secure Third-Party IP Integration in NoC-based SoC Platforms | 7. Secure boot, attestation and hardware root of trust | нет | https://doi.org/10.46586/tches.v2025.i4.317-340 |
| C027 | F0079 | 10 | HSP-V: Hypervisor-Less Static Partitioning for RISC-V COTS Platforms | 5. Bus, DMA, interrupt and peripheral isolation | нет | https://doi.org/10.1109/access.2024.3399601 |
| C028 | F0124 | 10 | Unleashing OpenTitan’s Potential: a Silicon-Ready Embedded Secure Element for Root of Trust and Cryptographic Offloading | 7. Secure boot, attestation and hardware root of trust | да, 29 стр.; Local PDF: §2.2/§3.1 OpenTitan pp. 6–9; §4 root-of-trust co-processor pp. 11–15; §5.2 lifecycle p. 17; §5.4 bootflow pp. 19–20; §6 physical implementation and benchmarks pp. 21–26. | https://doi.org/10.1145/3690823 |
| C029 | F0074 | 10 | CoVE | 5. Bus, DMA, interrupt and peripheral isolation | да, 7 стр.; Local PDF: RISC-V privilege levels and reference-architecture scope p. 1; §2 adversary/threat model p. 2; reference architecture and TSM/root of trust p. 3; §4 ISA primitives and domain assignment p. 4; §5 lifecycle/ABI p. 5; §6.4 SoC I/O, devices and IOMMU p. 6. | https://doi.org/10.1145/3587135.3592168 |
| C030 | F0125 | 10 | Security Verification of the OpenTitan Hardware Root of Trust | 7. Secure boot, attestation and hardware root of trust | нет | https://doi.org/10.1109/msec.2023.3251954 |
| C031 | F0072 | 10 | Towards a Formally Verified Security Monitor for VM-based Confidential Computing | 5. Bus, DMA, interrupt and peripheral isolation | да, 9 стр.; Local PDF: §3 Architecture Overview p. 3; §3.1 Threat Model and §3.2 Security Guarantees p. 4; §5 Implementation p. 6; §6 Memory Tracker pp. 6–7; §6.3 proof directions p. 8. | https://doi.org/10.1145/3623652.3623668 |
| C032 | F0082 | 10 | A Framework for Design, Verification, and Management of SoC Access Control Systems | 5. Bus, DMA, interrupt and peripheral isolation | нет | https://doi.org/10.1109/tc.2022.3209923 |
| C033 | F0091 | 10 | Aker: A Design and Verification Framework for Safe and Secure SoC Access Control | 5. Bus, DMA, interrupt and peripheral isolation | нет | https://doi.org/10.1109/iccad51958.2021.9643538 |
| C034 | F0094 | 9 | Enhancing configuration flexibility in an Open-Source RISC-V IOPMP IP | 5. Bus, DMA, interrupt and peripheral isolation | нет | https://hdl.handle.net/1822/101184 |

### Attacks / debug / zeroization

| Core_ID | Final_ID | Балл | Название | Раздел статьи | Локальный PDF | URL |
|---|---|---:|---|---|---|---|
| C035 | F0011 | 10 | Physical Memory Please: Practical Memory-Aliasing Attacks on RISC-V PMP | 4. CPU isolation: PMP/ePMP, privilege modes and enclaves | нет | https://doi.org/10.46586/uasc.2026.008 |
| C036 | F0162 | 10 | ZeroTrace: Provable Storage Sanitisation Through Modular Erasure Engines and Cryptographic Audit Attestation | 8. Debug lockdown, lifecycle control and secret zeroization | нет | https://doi.org/10.5281/zenodo.19511539 |
| C037 | F0128 | 10 | Fault Attacks on Access Control in Processors: Threat, Formal Analysis and Microarchitectural Mitigation | 7. Secure boot, attestation and hardware root of trust | нет | https://doi.org/10.1109/access.2023.3280804 |
| C038 | F0077 | 10 | A Secure JTAG Wrapper for SoC Testing and Debugging | 5. Bus, DMA, interrupt and peripheral isolation | нет | https://doi.org/10.1109/access.2022.3164712 |
| C039 | F0107 | 10 | SRAM has no chill: exploiting power domain separation to steal on-chip secrets | 6. Key path, secure memory and trusted-code storage | да, 13 стр.; Local PDF: §3 on-chip SRAM cold boot p. 3; §4 Attack Model p. 4; §5 Volt Boot p. 5; §6 Attack Evaluation pp. 6–7; §7 cache/register/iRAM attacks pp. 8–9; §8 mitigations p. 10; §9 related remanence attacks p. 11. | https://doi.org/10.1145/3503222.3507710 |
| C040 | F0019 | 10 | Bypassing Isolated Execution on RISC-V using Side-Channel-Assisted Fault-Injection and Its Countermeasure | 4. CPU isolation: PMP/ePMP, privilege modes and enclaves | нет | https://doi.org/10.46586/tches.v2022.i1.28-68 |

Правило для `Core_40`: использовать его для быстрого входа в предметную область и построения первичной карты, но не подгонять найденный пробел под этот список. После выбора направления сотрудник должен сформировать собственное тематическое ядро. Центральное утверждение подтверждается минимум одним первичным исследованием или официальной спецификацией. Обзоры C019/C022 подходят для структуры поля и терминологии, но не должны быть единственной опорой для численных или архитектурных выводов.

## 5. Ограничения базы и обязательная ручная проверка

### 5.1 Приоритетные записи

| Final_ID | Приоритет | Источник | Что сделать | URL |
|---|---|---|---|---|
| F0075 | BLOCKING | An In-Depth Study and Implementation of Protection Mechanisms For Embedded Devices Running Multiple Applications | Ссылка институционального хоста не отвечает. Найти рабочую страницу/PDF, подтвердить авторов, год, тип работы и точные страницы. | http://www.theses.fr/2020GRALM002/document |
| F0162 | BLOCKING | ZeroTrace: Provable Storage Sanitisation Through Modular Erasure Engines and Cryptographic Audit Attestation | Запись ведёт на Zenodo и обозначена как scholarly article. Найти издательскую версию; до этого считать repository/preprint evidence. | https://doi.org/10.5281/zenodo.19511539 |
| F0097 | HIGH | An open-source trusted execution environment for resource-constrained RISC-V MCUs | Доступен abstract/poster RISC-V Europe. Не переносить из него количественные результаты как из полной рецензируемой статьи. | https://riscv-europe.org/summit/2025/media/proceedings/2025-05-14-RISC-V-Summit-Europe-P3.2.04-CUNHA-abstract.pdf |
| F0094 | HIGH | Enhancing configuration flexibility in an Open-Source RISC-V IOPMP IP | Репозиторная запись об IOPMP IP. Уточнить, является ли материал статьёй, диссертацией или техническим отчётом, и исправить тип перед финальной выгрузкой. | https://hdl.handle.net/1822/101184 |
| F0055 | HIGH | Hardware Root of Trust en Sistemes RISC-V : Analysis and Evaluation of Open Source Approaches | Институциональная студенческая работа. Допустима для контекста реализации, но не как основное доказательство общей эффективности. | https://ddd.uab.cat/pub/tfg/2026/326568/hardware_root_of_trust_en_sistemes_risc-v.pdf |
| F0159 | HIGH | ATLAS: AI-Assisted Threat-to-Assertion Learning for System-on-Chip Security Verification | ATLAS — arXiv-препринт 2026. Проверить появление proceedings/journal version непосредственно перед подачей. | https://arxiv.org/abs/2603.01170 |
| F0004 | MEDIUM | Modern Hardware Security: A Review of Attacks and Countermeasures | Обзор размещён на arXiv; проверить наличие опубликованной версии и её площадку. | https://doi.org/10.48550/arxiv.2501.04394 |
| F0006 | MEDIUM | A Survey on RISC-V Security: Hardware and Architecture | Обзор безопасности RISC-V размещён на arXiv; использовать для навигации, а ключевые тезисы подтверждать первичными работами. | https://doi.org/10.48550/arxiv.2107.04175 |
| F0025 | HIGH | Keystone: A Framework for Architecting TEEs. | Ранняя версия Keystone. Не цитировать одновременно с F0026 и опубликованной F0012 без отдельной причины. | https://arxiv.org/abs/1907.10119v1 |
| F0026 | HIGH | Keystone: An Open Framework for Architecting TEEs | Препринт Keystone. По умолчанию заменить опубликованной F0012; оставить только для материала, отсутствующего в proceedings paper. | https://doi.org/10.48550/arxiv.1907.10119 |
| F0085 | HIGH | CoVE: Towards Confidential Computing on RISC-V Platforms | Препринт CoVE. По умолчанию использовать опубликованную F0074; препринт — только для дополнительных деталей. | https://doi.org/10.48550/arxiv.2304.06167 |

### 5.2 Все препринты и репозиторные версии

После обновления в таблице осталось 14 записей, явно обозначенных как preprint/repository. Они допустимы для state of the art и описания новых направлений, но перед подачей для каждой нужно повторить поиск опубликованной версии по названию, авторам и DOI.

| Final_ID | Год | Название | Текущий статус | URL |
|---|---:|---|---|---|
| F0025 | 2019 | Keystone: A Framework for Architecting TEEs. | Preprint / repository; peer review not confirmed | https://arxiv.org/abs/1907.10119v1 |
| F0026 | 2019 | Keystone: An Open Framework for Architecting TEEs | Preprint / repository; peer review not confirmed | https://doi.org/10.48550/arxiv.1907.10119 |
| F0059 | 2022 | An Exploratory Study of Attestation Mechanisms for Trusted Execution Environments | Preprint / repository; peer review not confirmed | https://doi.org/10.48550/arxiv.2204.06790 |
| F0069 | 2022 | Verifying RISC-V Physical Memory Protection | Preprint / repository; peer review not confirmed | https://doi.org/10.48550/arxiv.2211.02179 |
| F0085 | 2023 | CoVE: Towards Confidential Computing on RISC-V Platforms | Preprint / repository; peer review not confirmed | https://doi.org/10.48550/arxiv.2304.06167 |
| F0086 | 2025 | ACE: Confidential Computing for Embedded RISC-V Systems | Preprint / repository; peer review not confirmed | https://doi.org/10.48550/arxiv.2505.12995 |
| F0090 | 2022 | An Enclave-based TEE for SE-in-SoC in RISC-V Industry | Preprint / repository; peer review not confirmed | https://doi.org/10.48550/arxiv.2208.03631 |
| F0095 | 2026 | System-Level Isolation for Mixed-Criticality RISC-V SoCs: A "World" Reality Check | Preprint / repository; peer review not confirmed | https://doi.org/10.48550/arxiv.2602.05002 |
| F0122 | 2020 | A Lightweight Isolation Mechanism for Secure Branch Predictors | Preprint / repository; peer review not confirmed | https://doi.org/10.48550/arxiv.2005.08183 |
| F0135 | 2023 | Unlocking Hardware Security Assurance: The Potential of LLMs | Preprint / repository; peer review not confirmed | https://doi.org/10.48550/arxiv.2308.11042 |
| F0138 | 2023 | Information Flow Coverage Metrics for Hardware Security Verification | Preprint / repository; peer review not confirmed | https://doi.org/10.48550/arxiv.2304.08263 |
| F0143 | 2023 | (Security) Assertions by Large Language Models | Preprint / repository; peer review not confirmed | https://doi.org/10.48550/arxiv.2306.14027 |
| F0144 | 2023 | FVCARE:Formal Verification of Security Primitives in Resilient Embedded SoCs | Preprint / repository; peer review not confirmed | https://doi.org/10.48550/arxiv.2304.11489 |
| F0159 | 2026 | ATLAS: AI-Assisted Threat-to-Assertion Learning for System-on-Chip Security Verification | Preprint / repository; peer review not confirmed | https://arxiv.org/abs/2603.01170 |

Особые пары, которые нельзя бездумно цитировать одновременно:

- Keystone: опубликованная `F0012`; препринты `F0025` и `F0026`.
- CoVE: опубликованная `F0074`; препринт `F0085`.
- Для любых других совпадающих названий искать publisher version и оставлять одну каноническую запись, если версии не поддерживают разные утверждения.

### 5.3 Загруженные и проверенные PDF

Все 37 материалов, которые ранее нельзя было полнотекстово проверить через издательские страницы, получены локально. Для каждого подтверждены читаемость, соответствие Final_ID и страницы тематически значимых фрагментов. Их не нужно повторно искать перед началом работы: открывайте путь из столбца Local_PDF и используйте Local_Evidence_Location. Перед дословной цитатой всё равно перепроверьте конкретную страницу.

| Final_ID | Core_ID | Страниц | Источник | Где смотреть | Локальный файл |
|---|---|---:|---|---|---|
| F0001 | C022 | 35 | A Survey of RISC-V Secure Enclaves and Trusted Execution Environments | Local PDF: §2.2 “RISC-V Security Landscape” p. 3; §3 survey of RISC-V TEEs pp. 4–19; §4.1 design trade-offs p. 20; §4.3 secure I/O p. 21; §4.12 memory-isolation grouping p. 27. | /Users/igor/Library/CloudStorage/GoogleDrive-senushinigor@gmail.com/Мой диск/ЦАРКА/Активные проекты/Крипточип ГФ/05_Scientific_and_Patents/Статьи ГФ Крипточип/скачанные_статьи/F0001.pdf |
| F0002 | — | 39 | Advanced Hardware Security on Embedded Processors: A 2026 Systematic Review | Local PDF: CPU/PMP/privilege isolation pp. 22, 23, 24; key path and secret handling pp. 1, 2, 3; secure boot and attestation pp. 1, 2, 3. | /Users/igor/Library/CloudStorage/GoogleDrive-senushinigor@gmail.com/Мой диск/ЦАРКА/Активные проекты/Крипточип ГФ/05_Scientific_and_Patents/Статьи ГФ Крипточип/скачанные_статьи/F0002.pdf |
| F0007 | — | 17 | SoK: Understanding Design Choices and Pitfalls of Trusted Execution Environments | Local PDF: CPU/PMP/privilege isolation pp. 3, 4, 5; DMA and I/O isolation pp. 8; key path and secret handling pp. 1, 11. | /Users/igor/Library/CloudStorage/GoogleDrive-senushinigor@gmail.com/Мой диск/ЦАРКА/Активные проекты/Крипточип ГФ/05_Scientific_and_Patents/Статьи ГФ Крипточип/скачанные_статьи/F0007.pdf |
| F0008 | — | 15 | SoK: A Systematic Review of TEE Usage for Developing Trusted Applications | Local PDF: CPU/PMP/privilege isolation pp. 2, 3, 4; key path and secret handling pp. 9; secure boot and attestation pp. 2, 3, 4. | /Users/igor/Library/CloudStorage/GoogleDrive-senushinigor@gmail.com/Мой диск/ЦАРКА/Активные проекты/Крипточип ГФ/05_Scientific_and_Patents/Статьи ГФ Крипточип/скачанные_статьи/F0008.pdf |
| F0012 | C016 | 16 | Keystone | Local PDF: §3 “Keystone Overview” pp. 4–5; §4.1 “Memory Isolation” pp. 5–6; §6 “Security Analysis” pp. 9–10; §7 “Evaluation” pp. 10–12. | /Users/igor/Library/CloudStorage/GoogleDrive-senushinigor@gmail.com/Мой диск/ЦАРКА/Активные проекты/Крипточип ГФ/05_Scientific_and_Patents/Статьи ГФ Крипточип/скачанные_статьи/F0012.pdf |
| F0013 | C013 | 13 | HECTOR-V: A Heterogeneous CPU Architecture for a Secure RISC-V Execution Environment | Local PDF: §3 Threat Model p. 3; §4 Design pp. 3–6 (trusted I/O and security monitor); §5 Implementation pp. 6–9; §6.1 Secure Boot p. 9; §7 Security Discussion p. 10. | /Users/igor/Library/CloudStorage/GoogleDrive-senushinigor@gmail.com/Мой диск/ЦАРКА/Активные проекты/Крипточип ГФ/05_Scientific_and_Patents/Статьи ГФ Крипточип/скачанные_статьи/F0013.pdf |
| F0016 | C011 | 18 | DITES: A Lightweight and Flexible Dual-Core Isolated Trusted Execution SoC Based on RISC-V | Local PDF: §3.2 SoC Architecture p. 4; §3.3 Secure Hierarchical Bus p. 5; §3.5.1 IOPMP p. 8; §3.5.4 Confidential Access Policy p. 10; §3.6 Secure Boot pp. 10–11; §4 FPGA/ASIC evaluation pp. 11–15. | /Users/igor/Library/CloudStorage/GoogleDrive-senushinigor@gmail.com/Мой диск/ЦАРКА/Активные проекты/Крипточип ГФ/05_Scientific_and_Patents/Статьи ГФ Крипточип/скачанные_статьи/F0016.pdf |
| F0017 | C009 | 24 | A Trusted Execution Environment RISC-V System-on-Chip Compatible with Transport Layer Security 1.3 | Local PDF: architecture/root-of-trust contribution p. 3; §5 Secured Boot Flow pp. 11–13; §6 Experimental Results pp. 14–18; §6.4 Security Analysis p. 18; §6.5 comparison pp. 19–20. | /Users/igor/Library/CloudStorage/GoogleDrive-senushinigor@gmail.com/Мой диск/ЦАРКА/Активные проекты/Крипточип ГФ/05_Scientific_and_Patents/Статьи ГФ Крипточип/скачанные_статьи/F0017.pdf |
| F0022 | — | 16 | Moat | Local PDF: CPU/PMP/privilege isolation pp. 1, 2, 3; attack evidence pp. 1, 2, 3; formal verification pp. 1, 4, 5. | /Users/igor/Library/CloudStorage/GoogleDrive-senushinigor@gmail.com/Мой диск/ЦАРКА/Активные проекты/Крипточип ГФ/05_Scientific_and_Patents/Статьи ГФ Крипточип/скачанные_статьи/F0022.pdf |
| F0027 | C010 | 12 | SPEAR-V: Secure and Practical Enclave Architecture for RISC-V | Local PDF: §3 Threat Model p. 2; §4 Design Overview pp. 2–4; §5 Hardware Design pp. 4–6; §6 Software Design pp. 6–8; §7 Security Analysis p. 8. | /Users/igor/Library/CloudStorage/GoogleDrive-senushinigor@gmail.com/Мой диск/ЦАРКА/Активные проекты/Крипточип ГФ/05_Scientific_and_Patents/Статьи ГФ Крипточип/скачанные_статьи/F0027.pdf |
| F0030 | — | 18 | A Tale of Two Worlds | Local PDF: CPU/PMP/privilege isolation pp. 1, 2, 3; attack evidence pp. 1, 2, 3; formal verification pp. 5, 15. | /Users/igor/Library/CloudStorage/GoogleDrive-senushinigor@gmail.com/Мой диск/ЦАРКА/Активные проекты/Крипточип ГФ/05_Scientific_and_Patents/Статьи ГФ Крипточип/скачанные_статьи/F0030.pdf |
| F0038 | — | 15 | Cerberus | Local PDF: CPU/PMP/privilege isolation pp. 1, 2, 3; attack evidence pp. 3, 5, 6; formal verification pp. 1, 2, 3. | /Users/igor/Library/CloudStorage/GoogleDrive-senushinigor@gmail.com/Мой диск/ЦАРКА/Активные проекты/Крипточип ГФ/05_Scientific_and_Patents/Статьи ГФ Крипточип/скачанные_статьи/F0038.pdf |
| F0040 | — | 6 | VirTEE | Local PDF: CPU/PMP/privilege isolation pp. 1, 2, 3; attack evidence pp. 1, 2, 3. | /Users/igor/Library/CloudStorage/GoogleDrive-senushinigor@gmail.com/Мой диск/ЦАРКА/Активные проекты/Крипточип ГФ/05_Scientific_and_Patents/Статьи ГФ Крипточип/скачанные_статьи/F0040.pdf |
| F0042 | — | 15 | Formalizing, Verifying and Applying ISA Security Guarantees as Universal Contracts | Local PDF: CPU/PMP/privilege isolation pp. 1, 2, 3; attack evidence pp. 1, 3, 5; formal verification pp. 1, 2, 3. | /Users/igor/Library/CloudStorage/GoogleDrive-senushinigor@gmail.com/Мой диск/ЦАРКА/Активные проекты/Крипточип ГФ/05_Scientific_and_Patents/Статьи ГФ Крипточип/скачанные_статьи/F0042.pdf |
| F0044 | — | 14 | Verification of a Practical Hardware Security Architecture Through Static Information Flow Analysis | Local PDF: CPU/PMP/privilege isolation pp. 12, 13; attack evidence pp. 1, 2, 3; formal verification pp. 1, 2, 4. | /Users/igor/Library/CloudStorage/GoogleDrive-senushinigor@gmail.com/Мой диск/ЦАРКА/Активные проекты/Крипточип ГФ/05_Scientific_and_Patents/Статьи ГФ Крипточип/скачанные_статьи/F0044.pdf |
| F0047 | — | 14 | Secure TLBs | Local PDF: CPU/PMP/privilege isolation pp. 2, 3; attack evidence pp. 1, 2, 3. | /Users/igor/Library/CloudStorage/GoogleDrive-senushinigor@gmail.com/Мой диск/ЦАРКА/Активные проекты/Крипточип ГФ/05_Scientific_and_Patents/Статьи ГФ Крипточип/скачанные_статьи/F0047.pdf |
| F0049 | — | 31 | ISA semantics for ARMv8-a, RISC-v, and CHERI-MIPS | Local PDF: CPU/PMP/privilege isolation pp. 6; formal verification pp. 1, 2, 4. | /Users/igor/Library/CloudStorage/GoogleDrive-senushinigor@gmail.com/Мой диск/ЦАРКА/Активные проекты/Крипточип ГФ/05_Scientific_and_Patents/Статьи ГФ Крипточип/скачанные_статьи/F0049.pdf |
| F0052 | — | 7 | Dep-TEE: Decoupled Memory Protection for Secure and Scalable Inter-enclave Communication on RISC-V | Local PDF: CPU/PMP/privilege isolation pp. 1, 2, 3; attack evidence pp. 1, 2, 3. | /Users/igor/Library/CloudStorage/GoogleDrive-senushinigor@gmail.com/Мой диск/ЦАРКА/Активные проекты/Крипточип ГФ/05_Scientific_and_Patents/Статьи ГФ Крипточип/скачанные_статьи/F0052.pdf |
| F0054 | — | 13 | Hypervision Across Worlds | Local PDF: CPU/PMP/privilege isolation pp. 1, 2; attack evidence pp. 1, 2, 3; formal verification pp. 8, 12. | /Users/igor/Library/CloudStorage/GoogleDrive-senushinigor@gmail.com/Мой диск/ЦАРКА/Активные проекты/Крипточип ГФ/05_Scientific_and_Patents/Статьи ГФ Крипточип/скачанные_статьи/F0054.pdf |
| F0066 | — | 16 | Accelerating Extra Dimensional Page Walks for Confidential Computing | Local PDF: CPU/PMP/privilege isolation pp. 1, 2, 3; attack evidence pp. 6, 14, 15. | /Users/igor/Library/CloudStorage/GoogleDrive-senushinigor@gmail.com/Мой диск/ЦАРКА/Активные проекты/Крипточип ГФ/05_Scientific_and_Patents/Статьи ГФ Крипточип/скачанные_статьи/F0066.pdf |
| F0067 | — | 14 | SHAKTI-MS: a RISC-V processor for memory safety in C | Local PDF: attack evidence pp. 1, 2, 3. | /Users/igor/Library/CloudStorage/GoogleDrive-senushinigor@gmail.com/Мой диск/ЦАРКА/Активные проекты/Крипточип ГФ/05_Scientific_and_Patents/Статьи ГФ Крипточип/скачанные_статьи/F0067.pdf |
| F0070 | — | 9 | A Novel Memory Management for RISC-V Enclaves | Local PDF: CPU/PMP/privilege isolation pp. 1, 2, 3; attack evidence pp. 8, 9. | /Users/igor/Library/CloudStorage/GoogleDrive-senushinigor@gmail.com/Мой диск/ЦАРКА/Активные проекты/Крипточип ГФ/05_Scientific_and_Patents/Статьи ГФ Крипточип/скачанные_статьи/F0070.pdf |
| F0072 | C031 | 9 | Towards a Formally Verified Security Monitor for VM-based Confidential Computing | Local PDF: §3 Architecture Overview p. 3; §3.1 Threat Model and §3.2 Security Guarantees p. 4; §5 Implementation p. 6; §6 Memory Tracker pp. 6–7; §6.3 proof directions p. 8. | /Users/igor/Library/CloudStorage/GoogleDrive-senushinigor@gmail.com/Мой диск/ЦАРКА/Активные проекты/Крипточип ГФ/05_Scientific_and_Patents/Статьи ГФ Крипточип/скачанные_статьи/F0072.pdf |
| F0074 | C029 | 7 | CoVE | Local PDF: RISC-V privilege levels and reference-architecture scope p. 1; §2 adversary/threat model p. 2; reference architecture and TSM/root of trust p. 3; §4 ISA primitives and domain assignment p. 4; §5 lifecycle/ABI p. 5; §6.4 SoC I/O, devices and IOMMU p. 6. | /Users/igor/Library/CloudStorage/GoogleDrive-senushinigor@gmail.com/Мой диск/ЦАРКА/Активные проекты/Крипточип ГФ/05_Scientific_and_Patents/Статьи ГФ Крипточип/скачанные_статьи/F0074.pdf |
| F0080 | — | 25 | Hardware Security of Fog End-Devices for the Internet of Things | Local PDF: attack evidence pp. 1, 2, 4. | /Users/igor/Library/CloudStorage/GoogleDrive-senushinigor@gmail.com/Мой диск/ЦАРКА/Активные проекты/Крипточип ГФ/05_Scientific_and_Patents/Статьи ГФ Крипточип/скачанные_статьи/F0080.pdf |
| F0081 | — | 15 | Adaptive CHERI Compartmentalization for Heterogeneous Accelerators | Local PDF: DMA and I/O isolation pp. 2, 3, 4; CPU/PMP/privilege isolation pp. 4, 14; attack evidence pp. 1, 2, 3. | /Users/igor/Library/CloudStorage/GoogleDrive-senushinigor@gmail.com/Мой диск/ЦАРКА/Активные проекты/Крипточип ГФ/05_Scientific_and_Patents/Статьи ГФ Крипточип/скачанные_статьи/F0081.pdf |
| F0087 | — | 11 | Isadora | Local PDF: attack evidence pp. 1, 2, 7. | /Users/igor/Library/CloudStorage/GoogleDrive-senushinigor@gmail.com/Мой диск/ЦАРКА/Активные проекты/Крипточип ГФ/05_Scientific_and_Patents/Статьи ГФ Крипточип/скачанные_статьи/F0087.pdf |
| F0102 | — | 8 | A comparison study of intel SGX and AMD memory encryption technology | Local PDF: protected memory pp. 1, 2, 3; attack evidence pp. 1, 2, 3. | /Users/igor/Library/CloudStorage/GoogleDrive-senushinigor@gmail.com/Мой диск/ЦАРКА/Активные проекты/Крипточип ГФ/05_Scientific_and_Patents/Статьи ГФ Крипточип/скачанные_статьи/F0102.pdf |
| F0103 | — | 38 | Blockchain and Secure Element, a Hybrid Approach for Secure Energy Smart Meter Gateways | Local PDF: key path and secret handling pp. 4, 22; attack evidence pp. 1, 2, 6. | /Users/igor/Library/CloudStorage/GoogleDrive-senushinigor@gmail.com/Мой диск/ЦАРКА/Активные проекты/Крипточип ГФ/05_Scientific_and_Patents/Статьи ГФ Крипточип/скачанные_статьи/F0103.pdf |
| F0107 | C039 | 13 | SRAM has no chill: exploiting power domain separation to steal on-chip secrets | Local PDF: §3 on-chip SRAM cold boot p. 3; §4 Attack Model p. 4; §5 Volt Boot p. 5; §6 Attack Evaluation pp. 6–7; §7 cache/register/iRAM attacks pp. 8–9; §8 mitigations p. 10; §9 related remanence attacks p. 11. | /Users/igor/Library/CloudStorage/GoogleDrive-senushinigor@gmail.com/Мой диск/ЦАРКА/Активные проекты/Крипточип ГФ/05_Scientific_and_Patents/Статьи ГФ Крипточип/скачанные_статьи/F0107.pdf |
| F0124 | C028 | 29 | Unleashing OpenTitan’s Potential: a Silicon-Ready Embedded Secure Element for Root of Trust and Cryptographic Offloading | Local PDF: §2.2/§3.1 OpenTitan pp. 6–9; §4 root-of-trust co-processor pp. 11–15; §5.2 lifecycle p. 17; §5.4 bootflow pp. 19–20; §6 physical implementation and benchmarks pp. 21–26. | /Users/igor/Library/CloudStorage/GoogleDrive-senushinigor@gmail.com/Мой диск/ЦАРКА/Активные проекты/Крипточип ГФ/05_Scientific_and_Patents/Статьи ГФ Крипточип/скачанные_статьи/F0124.pdf |
| F0130 | — | 8 | Trusted Heterogeneous Disaggregated Architectures | Local PDF: secure boot and attestation pp. 2, 3, 4. | /Users/igor/Library/CloudStorage/GoogleDrive-senushinigor@gmail.com/Мой диск/ЦАРКА/Активные проекты/Крипточип ГФ/05_Scientific_and_Patents/Статьи ГФ Крипточип/скачанные_статьи/F0130.pdf |
| F0132 | — | 8 | Assessing the Performance of OpenTitan as Cryptographic Accelerator in Secure Open-Hardware System-on-Chips | Local PDF: secure boot and attestation pp. 2, 3, 8; key path and secret handling pp. 2, 3, 5. | /Users/igor/Library/CloudStorage/GoogleDrive-senushinigor@gmail.com/Мой диск/ЦАРКА/Активные проекты/Крипточип ГФ/05_Scientific_and_Patents/Статьи ГФ Крипточип/скачанные_статьи/F0132.pdf |
| F0134 | — | 18 | Modular Verification of Secure and Leakage-Free Systems: From Application Specification to Circuit-Level Implementation | Local PDF: secure boot and attestation pp. 11, 17; key path and secret handling pp. 11. | /Users/igor/Library/CloudStorage/GoogleDrive-senushinigor@gmail.com/Мой диск/ЦАРКА/Активные проекты/Крипточип ГФ/05_Scientific_and_Patents/Статьи ГФ Крипточип/скачанные_статьи/F0134.pdf |
| F0136 | — | 11 | Patching FPGAs: The Security Implications of Bitstream Modifications | Local PDF: secure boot and attestation pp. 4; key path and secret handling pp. 2, 3, 5. | /Users/igor/Library/CloudStorage/GoogleDrive-senushinigor@gmail.com/Мой диск/ЦАРКА/Активные проекты/Крипточип ГФ/05_Scientific_and_Patents/Статьи ГФ Крипточип/скачанные_статьи/F0136.pdf |
| F0141 | — | 6 | SCRAMBLE-CFI: Mitigating Fault-Induced Control-Flow Attacks on OpenTitan | Local PDF: secure boot and attestation pp. 1, 2, 6; key path and secret handling pp. 1. | /Users/igor/Library/CloudStorage/GoogleDrive-senushinigor@gmail.com/Мой диск/ЦАРКА/Активные проекты/Крипточип ГФ/05_Scientific_and_Patents/Статьи ГФ Крипточип/скачанные_статьи/F0141.pdf |
| F0150 | — | 20 | Secure Instruction and Data-Level Information Flow Tracking Model for RISC-V | Local PDF: attack evidence pp. 1, 2, 3. | /Users/igor/Library/CloudStorage/GoogleDrive-senushinigor@gmail.com/Мой диск/ЦАРКА/Активные проекты/Крипточип ГФ/05_Scientific_and_Patents/Статьи ГФ Крипточип/скачанные_статьи/F0150.pdf |

Важно: у 37 издательских адресов сохранён статус REACHABLE_RESTRICTED. Это исторический результат HTTP-проверки, а не требование заново искать PDF: наличие локального файла подтверждается отдельным статусом VERIFIED_LOCAL_PDF.

### 5.4 Опубликованные версии, исправленные 2026-08-04

Пять записей переведены с репозиторной/препринтной версии на официальную proceedings-версию. Дополнительных действий по ним сейчас не требуется.

| Final_ID | Год | Площадка | Официальный DOI / URL |
|---|---:|---|---|
| F0050 | 2021 | 30th USENIX Security Symposium (USENIX Security 21) | https://www.usenix.org/conference/usenixsecurity21/presentation/bahmani |
| F0056 | 2025 | 34th USENIX Security Symposium (USENIX Security 25) | https://www.usenix.org/conference/usenixsecurity25/presentation/kuhne |
| F0063 | 2022 | 31st USENIX Security Symposium (USENIX Security 22) | https://www.usenix.org/conference/usenixsecurity22/presentation/yu-jason |
| F0071 | 2024 | OPODIS 2023, Leibniz International Proceedings in Informatics (LIPIcs) | 10.4230/LIPIcs.OPODIS.2023.23 \| https://doi.org/10.4230/LIPIcs.OPODIS.2023.23 |
| F0147 | 2022 | 31st USENIX Security Symposium (USENIX Security 22) | https://www.usenix.org/conference/usenixsecurity22/presentation/trippel |

### 5.5 Ранее исправленные ссылки

Следующие записи были исправлены на финальном аудите. Они разрешены к использованию, но при финальной подготовке библиографии стоит один раз открыть новую ссылку.

| Final_ID | Исправление | Текущий URL |
|---|---|---|
| F0055 | Direct institutional-repository PDF substituted for an intermittently failing record page. | https://ddd.uab.cat/pub/tfg/2026/326568/hardware_root_of_trust_en_sistemes_risc-v.pdf |
| F0064 | Official USENIX publication page substituted for the unstable CiteSeer mirror. | https://www.usenix.org/conference/usenixsecurity15/technical-sessions/presentation/rane |
| F0083 | Official USENIX publication page substituted for the unstable CiteSeer mirror. | https://www.usenix.org/conference/usenixsecurity16/technical-sessions/presentation/costan |
| F0092 | Institutional thesis/defence record substituted for the intermittently failing theses.fr document endpoint. | https://www.lip6.fr/actualite/personnes-fiche.php?ident=D2315 |
| F0093 | Current official RISC-V IOPMP repository substituted for the obsolete mailing-list attachment. | https://github.com/riscv-non-isa/riscv-iopmp |
| F0097 | Official RISC-V Europe proceedings PDF substituted for the intermittently failing repository handle. | https://riscv-europe.org/summit/2025/media/proceedings/2025-05-14-RISC-V-Summit-Europe-P3.2.04-CUNHA-abstract.pdf |
| F0159 | Incorrect ACM DOI removed; authoritative arXiv record and DOI inserted. | https://arxiv.org/abs/2603.01170 |

## 6. Как формировать рабочий список литературы

До выбора научного пробела база используется как корпус для изучения, а не как готовая библиография. После выбора направления сотрудник должен сформировать три уровня источников.

### Уровень A — ближайшие аналоги

- 5–10 работ, которые решают максимально близкую задачу.
- Их необходимо прочитать полностью и сравнить по модели угроз, архитектуре, платформе, методике, результатам и ограничениям.
- Именно по отношению к ним формулируются отличие, новизна и предполагаемый вклад будущей статьи.

### Уровень B — рабочее ядро

- Примерно 30–50 источников для реальной работы над статьёй.
- Включает ближайшие аналоги, необходимые спецификации, ключевые первичные исследования, атаки, методы проверки и несколько качественных обзоров.
- `Core_40` служит стартом, но итоговое ядро формируется заново под выбранную тему.
- Источники `LOCAL_PDF` удобны для начала чтения, однако наличие локального файла не делает работу автоматически более значимой.

### Уровень C — расширенный библиографический пул

- До 100–200 источников для покрытия истории вопроса, альтернативных подходов, смежных платформ и дополнительных подтверждений.
- Конкретный источник включается в итоговую библиографию только тогда, когда он реально цитируется или обсуждается в тексте.
- Работы по TrustZone, SGX, CHERI и другим платформам допустимы для сравнительного контекста, но не являются прямым доказательством свойств RISC-V.

### Источники, требующие осторожности

- Все записи из раздела 5.1.
- Препринты и репозиторные версии, для которых ещё не найдена опубликованная работа.
- Материалы без проверенного полного текста, если из них нужны число, таблица, рисунок или точная цитата.
- Несколько версий одной работы: по умолчанию следует оставлять опубликованную версию, если препринт не содержит отдельно используемого материала.

Не следует использовать обзор как единственное доказательство экспериментального результата, препринт называть рецензируемой статьёй, официальную спецификацию представлять как независимую экспериментальную проверку или включать источник только ради увеличения списка литературы.

## 7. Быстрый выбор листа

| Задача | Открыть лист | Что искать |
|---|---|---|
| Посмотреть исходную карту тезисов | `Article_Mapping` | `Claim_ID`, `Source_ID`, `Exact_Location`; не считать готовым планом статьи |
| Начать сравнение механизмов и пробелов | `Evidence_Matrix` | CPU, DMA/IO, storage, key path, debug, zeroization, gap |
| Выбрать стартовые работы | `Core_40` | балл, категория, planned use, exact location; затем пересобрать ядро |
| Картировать поле и искать новые кластеры | `Final_200` | раздел, supported claim, publication type, peer-review status |
| Найти скачанный PDF и точные страницы | `URL_Audit` | `Local_PDF_Status`, `Local_PDF`, `Local_Evidence_Location` |
| Проверить издательскую ссылку | `URL_Audit` | status class, resolved URL, audit note |
| Увидеть ограничения и исправления | `Audit` | Stage 9 metrics, local PDF review, published-version corrections |

## 8. Чек-лист научного пробела и предлагаемой темы

- [ ] Ближайшие аналоги найдены не только в базе, но и дополнительным поиском.
- [ ] Для каждого аналога изучены модель угроз, метод, результаты и limitations.
- [ ] Пробел сформулирован как конкретное отсутствие знания, метода или проверки, а не как «найдено мало статей».
- [ ] Понятно, почему устранение пробела имеет научную или практическую ценность.
- [ ] Отличие от ближайших работ можно сформулировать одним-двумя точными предложениями.
- [ ] Предлагаемый вклад измерим или проверяем.
- [ ] Определены объект, исследовательский вопрос, платформа и метод оценки.
- [ ] Доступны необходимые RTL/IP, инструменты, FPGA/оборудование, данные или формальные средства.
- [ ] Scope можно выполнить в имеющиеся сроки.
- [ ] Проверены свежие публикации, препринты и цитирующие работы.
- [ ] Отдельно отмечено, какие утверждения являются выводами источников, а какие — синтезом научного сотрудника.
- [ ] Для выбранного направления сформировано рабочее ядро из 30–50 источников.
- [ ] После выбора целевого журнала отдельно проверяются Scopus, процентиль/квартиль, тематика и требования площадки.

## 9. Исходный корпус Final_200

Ниже перечислены все источники, прошедшие первоначальный отбор. Это исходный корпус, а не окончательный список литературы будущей статьи. Метки: `CORE` — входит в предварительный Core_40; `LOCAL_PDF` — загруженный полный текст проверен; `PREPRINT` — требуется поиск опубликованной версии; `MANUAL` — приоритетная ручная проверка; `RESTRICTED` — издатель ограничивает автоматический доступ; `PUBLISHED_UPDATE` — запись заменена на опубликованную proceedings-версию; `CORRECTED` — ссылка исправлена на финальном аудите.

### 1. Introduction and scope; 2. Review taxonomy; 3. Threat model, protected assets and trust boundaries

- **F0001 [CORE, LOCAL_PDF, RESTRICTED]** — A Survey of RISC-V Secure Enclaves and Trusted Execution Environments — Marouene Boubakri; Belhassen Zouari (2025). Electronics. https://doi.org/10.3390/electronics14214171
- **F0002 [LOCAL_PDF, RESTRICTED]** — Advanced Hardware Security on Embedded Processors: A 2026 Systematic Review — Ali Kia; Aaron W Storey; Masudul H. Imtiaz (2026). Electronics. https://doi.org/10.3390/electronics15051135
- **F0003** — SoK: Understanding the Prevailing Security Vulnerabilities in TrustZone-assisted TEE Systems — David Cerdeira; Nuno Santos; Pedro Fonseca; Sandro Pinto (2020). 2020 IEEE Symposium on Security and Privacy (SP). https://doi.org/10.1109/sp40000.2020.00061
- **F0004 [MANUAL]** — Modern Hardware Security: A Review of Attacks and Countermeasures — Jyotiprakash Mishra; Sanjay K. Sahay (2025). arXiv (Cornell University). https://doi.org/10.48550/arxiv.2501.04394
- **F0005** — A Survey of Recent Developments in Testability, Safety and Security of RISC-V Processors — Jens Anders; Pablo Andreu; Bernd Becker; Steffen Becker; Riccardo Cantoro; Nikolaos I. Deligiannis; Nourhan Elhamawy; Tobias Faller; Carles Hernández; Nele Mentens; Mahnaz Namazi Rizi; Ilia Polian; Abolfazl Sajadi; Mathias Sauer; Denis Schwachhofer; M. Sonza Reorda; Todor Stefanov; Ilya Tuzov; Stefan Wagner; Nuša Zidarič (2023). 2023 IEEE European Test Symposium (ETS). https://doi.org/10.1109/ets56758.2023.10174099
- **F0006 [CORE, MANUAL]** — A Survey on RISC-V Security: Hardware and Architecture — Tao Lű (2021). arXiv (Cornell University). https://doi.org/10.48550/arxiv.2107.04175
- **F0007 [LOCAL_PDF, RESTRICTED]** — SoK: Understanding Design Choices and Pitfalls of Trusted Execution Environments — M. Li; Yuheng Yang; Guoxing Chen; Mengjia Yan; Yinqian Zhang (2024). Proceedings of the 19th ACM Asia Conference on Computer and Communications Security. https://doi.org/10.1145/3634737.3644993
- **F0008 [LOCAL_PDF, RESTRICTED]** — SoK: A Systematic Review of TEE Usage for Developing Trusted Applications — Arttu Paju; Muhammad Javed; Juha Nurmi; Juha Savimäki; Brian McGillion; Billy Bob Brumley (2023). Proceedings of the 18th International Conference on Availability, Reliability and Security. https://doi.org/10.1145/3600160.3600169
- **F0009** — From Cryptography to Logic Locking: A Survey on the Architecture Evolution of Secure Scan Chains — Kimia Zamiri Azar; Hadi Mardani Kamali; Houman Homayoun; Avesta Sasan (2021). IEEE Access. https://doi.org/10.1109/access.2021.3080257
- **F0010** — SoK: Research Perspectives and Challenges for Bitcoin and Cryptocurrencies — Joseph Bonneau; Andrew Miller; Jeremy Clark; Arvind Narayanan; Joshua A. Kroll; Edward W. Felten (2015). 2015 IEEE Symposium on Security and Privacy. https://doi.org/10.1109/sp.2015.14

### 4. CPU isolation: PMP/ePMP, privilege modes and enclaves

- **F0011 [CORE]** — Physical Memory Please: Practical Memory-Aliasing Attacks on RISC-V PMP — Antonis Louka; Jesse De Meulemeester; Steven Keuchel; Ingrid Verbauwhede; Jo Van Bulck (2026). Proceedings of the Microarchitecture Security Conference. https://doi.org/10.46586/uasc.2026.008
- **F0012 [CORE, LOCAL_PDF, RESTRICTED]** — Keystone — Dayeol Lee; David Kohlbrenner; Shweta Shinde; Krste Asanović; Dawn Song (2020). Proceedings of the Fifteenth European Conference on Computer Systems. https://doi.org/10.1145/3342195.3387532
- **F0013 [CORE, LOCAL_PDF, RESTRICTED]** — HECTOR-V: A Heterogeneous CPU Architecture for a Secure RISC-V Execution Environment — Pascal Nasahl; Robert Schilling; Mario Werner; Stefan Mangard (2021). Proceedings of the 2021 ACM Asia Conference on Computer and Communications Security. https://doi.org/10.1145/3433210.3453112
- **F0014** — AnyTEE: An Open and Interoperable Software Defined TEE Framework — David Cerdeira; José Martins; Nuno Santos; Sandro Pinto (2025). IEEE Access. https://doi.org/10.1109/access.2025.3581487
- **F0015 [CORE]** — Towards Designing a Secure RISC-V System-on-Chip: ITUS — Vinay Kumar; Suman Deb; Naina Gupta; Shivam Bhasin; Jawad Haj-Yahya; Anupam Chattopadhyay; Avi Mendelson (2020). Journal of Hardware and Systems Security. https://doi.org/10.1007/s41635-020-00108-8
- **F0016 [CORE, LOCAL_PDF, RESTRICTED]** — DITES: A Lightweight and Flexible Dual-Core Isolated Trusted Execution SoC Based on RISC-V — Yuehai Chen; Huarun Chen; Shaozhen Chen; Chao Han; Wujian Ye; Yijun Liu; Huihui Zhou (2022). Sensors. https://doi.org/10.3390/s22165981
- **F0017 [CORE, LOCAL_PDF, RESTRICTED]** — A Trusted Execution Environment RISC-V System-on-Chip Compatible with Transport Layer Security 1.3 — Binh Kieu-Do-Nguyen; Khai-Duy Nguyen; Tuan-Kiet Dang; Nguyễn Thế Bình; Cuong Pham‐Quoc; Tran Ngoc Thinh; Cong‐Kha Pham; Trong-Thuc Hoang (2024). Electronics. https://doi.org/10.3390/electronics13132508
- **F0018** — Lightweight Secure-Boot Architecture for RISC-V System-on-Chip — Jawad Haj-Yahya; Ming Ming Wong; Vikramkumar Pudi; Shivam Bhasin; Anupam Chattopadhyay (2019). 20th International Symposium on Quality Electronic Design (ISQED). https://doi.org/10.1109/isqed.2019.8697657
- **F0019 [CORE]** — Bypassing Isolated Execution on RISC-V using Side-Channel-Assisted Fault-Injection and Its Countermeasure — Shoei Nashimoto; Daisuke Suzuki; Rei Ueno; Naofumi Homma (2021). IACR Transactions on Cryptographic Hardware and Embedded Systems. https://doi.org/10.46586/tches.v2022.i1.28-68
- **F0020** — Trusted Execution Environment Hardware by Isolated Heterogeneous Architecture for Key Scheduling — Trong-Thuc Hoang; Ckristian Duran; Ronaldo Serrano; Marco Sarmiento; Khai-Duy Nguyen; Akira Tsukamoto; Kuniyasu Suzaki; Cong‐Kha Pham (2022). IEEE Access. https://doi.org/10.1109/access.2022.3169767
- **F0021** — CARE: Lightweight Attack Resilient Secure Boot Architecture with Onboard Recovery for RISC-V based SOC — Avani Dave; Nilanjan Banerjee; Chintan Patel (2021). 2021 22nd International Symposium on Quality Electronic Design (ISQED). https://doi.org/10.1109/isqed51717.2021.9424322
- **F0022 [LOCAL_PDF, RESTRICTED]** — Moat — Rohit Sinha; Sriram K. Rajamani; Sanjit A. Seshia; Kapil Vaswani (2015). Proceedings of the 22nd ACM SIGSAC Conference on Computer and Communications Security. https://doi.org/10.1145/2810103.2813608
- **F0023** — CHERI-TrEE: Flexible enclaves on capability machines — Thomas Van Strydonck; Job Noorman; Jennifer Jackson; Leonardo Alves Dias; Robin Vanderstraeten; David Oswald; Frank Piessens; Dominique Devriese (2023). 2023 IEEE 8th European Symposium on Security and Privacy (EuroS&amp;P). https://doi.org/10.1109/eurosp57164.2023.00070
- **F0024** — MeetGo: A Trusted Execution Environment for Remote Applications on FPGA — Hyunyoung Oh; Kevin Nam; Seongil Jeon; Yeongpil Cho; Yunheung Paek (2021). IEEE Access. https://doi.org/10.1109/access.2021.3069223
- **F0025 [PREPRINT, MANUAL]** — Keystone: A Framework for Architecting TEEs. — Dayeol Lee; David Kohlbrenner; Shweta Shinde; Dawn Song; Krste Asanović (2019). arXiv (Cornell University). https://arxiv.org/abs/1907.10119v1
- **F0026 [PREPRINT, MANUAL]** — Keystone: An Open Framework for Architecting TEEs — Dayeol Lee; David Kohlbrenner; Shweta Shinde; Dawn Song; Krste Asanović (2019). arXiv (Cornell University). https://doi.org/10.48550/arxiv.1907.10119
- **F0027 [CORE, LOCAL_PDF, RESTRICTED]** — SPEAR-V: Secure and Practical Enclave Architecture for RISC-V — David Schrammel; Moritz Waser; Lukas Lamster; Martin Unterguggenberger; Stefan Mangard (2023). Proceedings of the ACM Asia Conference on Computer and Communications Security. https://doi.org/10.1145/3579856.3595784
- **F0028 [CORE]** — uTango: An Open-Source TEE for IoT Devices — Daniel Oliveira; Tiago Gomes; Sandro Pinto (2022). IEEE Access. https://doi.org/10.1109/access.2022.3152781
- **F0029** — Towards Dependable RISC-V Cores for Edge Computing Devices — Pegdwende Romaric Nikiema; Alessandro Palumbo; Allan Aasma; Luca Cassano; Angeliki Kritikakou; Ari Kulmala; Jari Lukkarila; Marco Ottavi; Rafail Psiakis; Marcello Traiola (2023). 2023 IEEE 29th International Symposium on On-Line Testing and Robust System Design (IOLTS). https://doi.org/10.1109/iolts59296.2023.10224862
- **F0030 [LOCAL_PDF, RESTRICTED]** — A Tale of Two Worlds — Jo Van Bulck; David Oswald; Eduard Marin; Abdulla Aldoseri; Flavio D. Garcia; Frank Piessens (2019). Proceedings of the 2019 ACM SIGSAC Conference on Computer and Communications Security. https://doi.org/10.1145/3319535.3363206
- **F0031 [CORE]** — TIMBER-V: Tag-Isolated Memory Bringing Fine-grained Enclaves to RISC-V — Samuel Weiser; Mario Werner; Ferdinand Brasser; Maja Malenko; Stefan Mangard; Ahmad‐Reza Sadeghi (2019). Proceedings 2019 Network and Distributed System Security Symposium. https://doi.org/10.14722/ndss.2019.23068
- **F0032** — Enabling Rack-scale Confidential Computing using Heterogeneous Trusted Execution Environment — Jianping Zhu; Rui Hou; XiaoFeng Wang; Wenhao Wang; Jiangfeng Cao; Boyan Zhao; Zhongpu Wang; Yuhui Zhang; Jiameng Ying; Lixin Zhang; Dan Meng (2020). 2020 IEEE Symposium on Security and Privacy (SP). https://doi.org/10.1109/sp40000.2020.00054
- **F0033** — Iso-X: A Flexible Architecture for Hardware-Managed Isolated Execution — Dmitry Evtyushkin; Jesse Elwell; Meltem Özsoy; Dmitry Ponomarev; Nael Abu‐Ghazaleh; Ryan Riley (2014). 2014 47th Annual IEEE/ACM International Symposium on Microarchitecture. https://doi.org/10.1109/micro.2014.25
- **F0034** — Quick Boot of Trusted Execution Environment With Hardware Accelerators — Trong-Thuc Hoang; Ckristian Duran; Duc-Thinh Nguyen-Hoang; Duc-Hung Le; Akira Tsukamoto; Kuniyasu Suzaki; Cong‐Kha Pham (2020). IEEE Access. https://doi.org/10.1109/access.2020.2987617
- **F0035** — SANCTUARY: ARMing TrustZone with User-space Enclaves — Ferdinand Brasser; David Gen�s; Patrick Jauernig; Ahmad‐Reza Sadeghi; Emmanuel Stapf (2019). Proceedings 2019 Network and Distributed System Security Symposium. https://doi.org/10.14722/ndss.2019.23448
- **F0036** — LIRA-V: Lightweight Remote Attestation for Constrained RISC-V Devices — Carlton Shepherd; Konstantinos Markantonakis; Georges-Axel Jaloyan (2021). 2021 IEEE Security and Privacy Workshops (SPW). https://doi.org/10.1109/spw53761.2021.00036
- **F0037** — TS-Perf: General Performance Measurement of Trusted Execution Environment and Rich Execution Environment on Intel SGX, Arm TrustZone, and RISC-V Keystone — Kuniyasu Suzaki; Kenta Nakajima; Tsukasa Oi; Akira Tsukamoto (2021). IEEE Access. https://doi.org/10.1109/access.2021.3112202
- **F0038 [LOCAL_PDF, RESTRICTED]** — Cerberus — Dayeol Lee; Kevin Cheang; Alexander Thomas; Ping Lu; Pranav Gaddamadugu; Anjo Vahldiek-Oberwagner; Mona Vij; Dawn Song; Sanjit A. Seshia; Krste Asanović (2022). Proceedings of the 2022 ACM SIGSAC Conference on Computer and Communications Security. https://doi.org/10.1145/3548606.3560595
- **F0039** — Offline Model Guard: Secure and Private ML on Mobile Devices — Sebastian P. Bayerl; Tommaso Frassetto; Patrick Jauernig; Korbinian Riedhammer; Ahmad‐Reza Sadeghi; Thomas Schneider; Emmanuel Stapf; Christian Weinert (2020). TUbilio (Technical University of Darmstadt). https://doi.org/10.23919/date48585.2020.9116560
- **F0040 [LOCAL_PDF, RESTRICTED]** — VirTEE — Jian‐qiang Wang; Pouya Mahmoody; Ferdinand Brasser; Patrick Jauernig; Ahmad‐Reza Sadeghi; Donghui Yu; Dahan Pan; Yuanyuan Zhang (2022). Proceedings of the 59th ACM/IEEE Design Automation Conference. https://doi.org/10.1145/3489517.3530436
- **F0041 [CORE]** — In Hardware We Trust? From TPM to Enclave Computing on RISC-V — Emmanuel Stapf; Patrick Jauernig; Ferdinand Brasser; Ahmad‐Reza Sadeghi (2021). 2021 IFIP/IEEE 29th International Conference on Very Large Scale Integration (VLSI-SoC). https://doi.org/10.1109/vlsi-soc53125.2021.9606968
- **F0042 [LOCAL_PDF, RESTRICTED]** — Formalizing, Verifying and Applying ISA Security Guarantees as Universal Contracts — Sander Huyghebaert; Steven Keuchel; Coen De Roover; Dominique Devriese (2023). Proceedings of the 2023 ACM SIGSAC Conference on Computer and Communications Security. https://doi.org/10.1145/3576915.3616602
- **F0043** — ZION: A Practical Confidential Virtual Machine Architecture on Commodity RISC-V Processors — Jie Wang; Juan Wang; Yinqian Zhang (2025). 2025 62nd ACM/IEEE Design Automation Conference (DAC). https://doi.org/10.1109/dac63849.2025.11133121
- **F0044 [LOCAL_PDF, RESTRICTED]** — Verification of a Practical Hardware Security Architecture Through Static Information Flow Analysis — Andrew Ferraiuolo; Rui Xu; Danfeng Zhang; Andrew C. Myers; G. Edward Suh (2017). Proceedings of the Twenty-Second International Conference on Architectural Support for Programming Languages and Operating Systems. https://doi.org/10.1145/3037697.3037739
- **F0045** — Twine: An Embedded Trusted Runtime for WebAssembly — James Menetrey; Marcelo Pasin; Pascal Felber; Valerio Schiavoni (2021). 2021 IEEE 37th International Conference on Data Engineering (ICDE). https://doi.org/10.1109/icde51399.2021.00025
- **F0046 [CORE]** — RISC-V Privileged Architecture — Machine-Level ISA / Physical Memory Protection — RISC-V International (2026). RISC-V International. https://docs.riscv.org/reference/isa/v20260120/priv/machine.html
- **F0047 [LOCAL_PDF, RESTRICTED]** — Secure TLBs — Shuwen Deng; Wenjie Xiong; Jakub Szefer (2019). Proceedings of the 46th International Symposium on Computer Architecture. https://doi.org/10.1145/3307650.3322238
- **F0048** — CVA6 RISC-V Virtualization: Architecture, Microarchitecture, and Design Space Exploration — Bruno Costa Martins de Sá; Luca Valente; José Martins; Davide Rossi; Luca Benini; Sandro Pinto (2023). IEEE Transactions on Very Large Scale Integration (VLSI) Systems. https://doi.org/10.1109/tvlsi.2023.3302837
- **F0049 [LOCAL_PDF, RESTRICTED]** — ISA semantics for ARMv8-a, RISC-v, and CHERI-MIPS — Alasdair Armstrong; Thomas Bauereiß; B. K. Campbell; Alastair Reid; Kathryn E. Gray; Robert M. Norton; Prashanth Mundkur; Mark P. Wassell; Jon French; Christopher Pulte; Shaked Flur; Ian Stark; Neel Krishnaswami; Peter Sewell (2019). Proceedings of the ACM on Programming Languages. https://doi.org/10.1145/3290384
- **F0050 [CORE, PUBLISHED_UPDATE]** — CURE: A Security Architecture with CUstomizable and Resilient Enclaves — Raad Bahmani; Ferdinand Brasser; Ghada Dessouky; Patrick Jauernig; Matthias Klimmek; Ahmad‐Reza Sadeghi; Emmanuel Stapf (2021). 30th USENIX Security Symposium (USENIX Security 21). https://www.usenix.org/conference/usenixsecurity21/presentation/bahmani
- **F0051** — LVI: Hijacking Transient Execution through Microarchitectural Load Value Injection — Jo Van Bulck; Daniel Moghimi; Michael Schwarz; Moritz Lippi; Marina Minkin; Daniel Genkin; Yuval Yarom; Berk Sunar; Daniel Gruss; Frank Piessens (2020). 2020 IEEE Symposium on Security and Privacy (SP). https://doi.org/10.1109/sp40000.2020.00089
- **F0052 [LOCAL_PDF, RESTRICTED]** — Dep-TEE: Decoupled Memory Protection for Secure and Scalable Inter-enclave Communication on RISC-V — Shangjie Pan; Xuanyao Peng; Zeyuan Man; Xiquan Zhao; Dongrong Zhang; Bicheng Yang; Dong Du; Hang Lü; Yubin Xia; Xiaowei Li (2025). Proceedings of the 30th Asia and South Pacific Design Automation Conference. https://doi.org/10.1145/3658617.3697763
- **F0053** — Enclave Application Cache for RISC-V Keystone — Takumu Umezawa; Akihiro Saiki; Keiji Kimura (2025). 2025 IEEE European Symposium on Security and Privacy Workshops (EuroS&amp;amp;PW). https://doi.org/10.1109/eurospw67616.2025.00055
- **F0054 [LOCAL_PDF, RESTRICTED]** — Hypervision Across Worlds — Ahmed M. Azab; Peng Ning; Jitesh Shah; Quan Chen; Rohan Bhutkar; Guruprasad Ganesh; Jia Ma; Wenbo Shen (2014). Proceedings of the 2014 ACM SIGSAC Conference on Computer and Communications Security. https://doi.org/10.1145/2660267.2660350
- **F0055 [MANUAL, CORRECTED]** — Hardware Root of Trust en Sistemes RISC-V : Analysis and Evaluation of Open Source Approaches — Pau Romaguera Palomé; Universitat Autònoma de Barcelona. Escola d'Enginyeria (2026). Dipòsit Digital de Documents de la UAB (Universitat Autònoma de Barcelona). https://ddd.uab.cat/pub/tfg/2026/326568/hardware_root_of_trust_en_sistemes_risc-v.pdf
- **F0056 [CORE, PUBLISHED_UPDATE]** — Dorami: Privilege Separating Security Monitor on RISC-V TEEs — Mark Kuhne; Stavros Volos; Shweta Shinde (2025). 34th USENIX Security Symposium (USENIX Security 25). https://www.usenix.org/conference/usenixsecurity25/presentation/kuhne
- **F0057** — RT-TEE: Real-time System Availability for Cyber-physical Systems using ARM TrustZone — Jinwen Wang; Ao Li; Haoran Li; Chenyang Lu; Ning Zhang (2022). 2022 IEEE Symposium on Security and Privacy (SP). https://doi.org/10.1109/sp46214.2022.9833604
- **F0058** — Is RISC-V ready for Space? A Security Perspective — Luca Cassano; Stefano Di Mascio; Alessandro Palumbo; Alessandra Menicucci; Gianluca Furano; Giuseppe Bianchi; Marco Ottavi (2022). 2022 IEEE International Symposium on Defect and Fault Tolerance in VLSI and Nanotechnology Systems (DFT). https://doi.org/10.1109/dft56152.2022.9962352
- **F0059 [PREPRINT]** — An Exploratory Study of Attestation Mechanisms for Trusted Execution Environments — Jämes Ménétrey; Christian Göttel; Marcelo Pasin; Pascal Felber; Valerio Schiavoni (2022). ArXiv.org. https://doi.org/10.48550/arxiv.2204.06790
- **F0060 [CORE]** — Smepmp Extension, Version 1.0 — RISC-V International (2026). RISC-V International. https://docs.riscv.org/reference/isa/v20260120/priv/smepmp.html
- **F0061** — Bao: A Lightweight Static Partitioning Hypervisor for Modern Multi-Core Embedded Systems — José Martins; Adriano Tavares; Marco Solieri; Marko Bertogna; Sandro Pinto (2020). DROPS (Schloss Dagstuhl – Leibniz Center for Informatics). https://doi.org/10.4230/oasics.ng-res.2020.3
- **F0062** — Demonstrating Post-Quantum Remote Attestation for RISC-V Devices — Maximilian Barger; Marco Brohet; Francesco Regazzoni (2024). 2024 Design, Automation &amp;amp; Test in Europe Conference &amp;amp; Exhibition (DATE). https://doi.org/10.23919/date58400.2024.10546557
- **F0063 [PUBLISHED_UPDATE]** — Elasticlave: An Efficient Memory Model for Enclaves — Jason Zhijingcheng Yu; Shweta Shinde; Trevor E. Carlson; Prateek Saxena (2022). 31st USENIX Security Symposium (USENIX Security 22). https://www.usenix.org/conference/usenixsecurity22/presentation/yu-jason
- **F0064 [CORRECTED]** — Raccoon: closing digital side-channels through obfuscated execution — Ashay Rane; Calvin Lin; Mohit Tiwari (2015). 24th USENIX Security Symposium (USENIX Security 15). https://www.usenix.org/conference/usenixsecurity15/technical-sessions/presentation/rane
- **F0065** — CHERI: A Hybrid Capability-System Architecture for Scalable Software Compartmentalization — Robert N. M. Watson; Jonathan Woodruff; Peter G. Neumann; Simon W. Moore; Jonathan Anderson; David Chisnall; Nirav Dave; Brooks Davis; Khilan Gudka; Ben Laurie; Steven J. Murdoch; Robert M. Norton; Michael Roe; Stacey Son; Munraj Vadera (2015). 2015 IEEE Symposium on Security and Privacy. https://doi.org/10.1109/sp.2015.9
- **F0066 [LOCAL_PDF, RESTRICTED]** — Accelerating Extra Dimensional Page Walks for Confidential Computing — Dong Du; Bicheng Yang; Yubin Xia; Haibo Chen (2023). 56th Annual IEEE/ACM International Symposium on Microarchitecture. https://doi.org/10.1145/3613424.3614293
- **F0067 [LOCAL_PDF, RESTRICTED]** — SHAKTI-MS: a RISC-V processor for memory safety in C — Sourav Das; R. Harikrishnan Unnithan; Arjun Menon; Chester Rebeiro; Kamakoti Veezhinathan (2019). Proceedings of the 20th ACM SIGPLAN/SIGBED International Conference on Languages, Compilers, and Tools for Embedded Systems. https://doi.org/10.1145/3316482.3326356
- **F0068 [CORE]** — Memory Encryption Support for an FPGA-based RISC-V Implementation — Alessandro Cilardo (2021). 2021 16th International Conference on Design &amp; Technology of Integrated Systems in Nanoscale Era (DTIS). https://doi.org/10.1109/dtis53253.2021.9505064
- **F0069 [CORE, PREPRINT]** — Verifying RISC-V Physical Memory Protection — Kevin Cheang; Cameron Rasmussen; Dayeol Lee; David W. Kohlbrenner; Krste Asanović; Sanjit A. Seshia (2022). arXiv (Cornell University). https://doi.org/10.48550/arxiv.2211.02179
- **F0070 [LOCAL_PDF, RESTRICTED]** — A Novel Memory Management for RISC-V Enclaves — Haonan Li; Weijie Huang; Mingde Ren; Hongyi Lu; Zhenyu Ning; Heming Cui; Fengwei Zhang (2021). Workshop on Hardware and Architectural Support for Security and Privacy. https://doi.org/10.1145/3505253.3505257
- **F0071 [PUBLISHED_UPDATE]** — A Holistic Approach for Trustworthy Distributed Systems with WebAssembly and TEEs — Arusoaie, Andrei; Bărbieru, Claudiu-Nicu; Captarencu, Oana-Otilia; Felber, Pascal; Libert, Corentin; Onica, Emanuel; Rivière, Etienne; Schiavoni, Valerio; Yuhala, Peterson (2024). OPODIS 2023, Leibniz International Proceedings in Informatics (LIPIcs). https://doi.org/10.4230/LIPIcs.OPODIS.2023.23

### 5. Bus, DMA, interrupt and peripheral isolation

- **F0072 [CORE, LOCAL_PDF, RESTRICTED]** — Towards a Formally Verified Security Monitor for VM-based Confidential Computing — Wojciech Ozga; Guerney D. H. Hunt; Michael Le; Elaine R. Palmer; Avraham Shinnar (2023). Proceedings of the 12th International Workshop on Hardware and Architectural Support for Security and Privacy. https://doi.org/10.1145/3623652.3623668
- **F0073** — Rethinking Trusted Execution Environments in the Age of Reconfigurable Computing — S. P. Pereira; David Cerdeira; Cristiano Rodrigues; Sandro Pinto (2025). IEEE Access. https://doi.org/10.1109/access.2025.3635270
- **F0074 [CORE, LOCAL_PDF, RESTRICTED]** — CoVE — Ravi Sahita; Vedvyas Shanbhogue; Andrew Bresticker; Atul Khare; Atish Patra; Samuel Ortiz; Dylan Reid; Rajnesh Kanwal (2023). Proceedings of the 20th ACM International Conference on Computing Frontiers. https://doi.org/10.1145/3587135.3592168
- **F0075 [MANUAL, TRANSIENT]** — An In-Depth Study and Implementation of Protection Mechanisms For Embedded Devices Running Multiple Applications — Abderrahmane Sensaoui (2020). theses.fr (ABES). http://www.theses.fr/2020GRALM002/document
- **F0076** — SofTEE: Software-Based Trusted Execution Environment for User Applications — Unsung Lee; Chanik Park (2020). IEEE Access. https://doi.org/10.1109/access.2020.3006703
- **F0077 [CORE]** — A Secure JTAG Wrapper for SoC Testing and Debugging — Kuen-Jong Lee; Zheng-Yao Lu; Shih-Chun Yeh (2022). IEEE Access. https://doi.org/10.1109/access.2022.3164712
- **F0078** — Composite Enclaves: Towards Disaggregated Trusted Execution — Moritz Schneider; Aritra Dhar; Ivan Puddu; Kari Kostiainen; Srđjan Čapkun (2021). IACR Transactions on Cryptographic Hardware and Embedded Systems. https://doi.org/10.46586/tches.v2022.i1.630-656
- **F0079 [CORE]** — HSP-V: Hypervisor-Less Static Partitioning for RISC-V COTS Platforms — João Sousa; José Martins; Tiago Gomes; Sandro Pinto (2024). IEEE Access. https://doi.org/10.1109/access.2024.3399601
- **F0080 [LOCAL_PDF, RESTRICTED]** — Hardware Security of Fog End-Devices for the Internet of Things — İsmail Bütün; Alparslan Sari; Patrik Österberg (2020). Sensors. https://doi.org/10.3390/s20205729
- **F0081 [LOCAL_PDF, RESTRICTED]** — Adaptive CHERI Compartmentalization for Heterogeneous Accelerators — Jianyi Cheng; A. Theodore Markettos; Alexandre Joannou; Paul Metzger; Matthew Naylor; Peter Rugg; Timothy M. Jones (2025). Proceedings of the 52nd Annual International Symposium on Computer Architecture. https://doi.org/10.1145/3695053.3731062
- **F0082 [CORE]** — A Framework for Design, Verification, and Management of SoC Access Control Systems — Francesco Restuccia; Andres Meza; Ryan Kastner; Jason Oberg (2022). IEEE Transactions on Computers. https://doi.org/10.1109/tc.2022.3209923
- **F0083 [CORRECTED]** — Sanctum: Minimal Hardware Extensions for Strong Software Isolation — Victor Costan; Ilia A. Lebedev; Srinivas Devadas (2016). 25th USENIX Security Symposium (USENIX Security 16). https://www.usenix.org/conference/usenixsecurity16/technical-sessions/presentation/costan
- **F0084** — Tyche: Composable Isolation as a Foundation to Manage Trust in the Cloud — Adrien Ghosn; Charly Castes; Neelu S. Kalani; Yuchen Qian; Marios Kogias; Edouard Bugnion (2026). 2026 IEEE 11th European Symposium on Security and Privacy (EuroS&amp;P). https://doi.org/10.1109/eurosp68448.2026.00055
- **F0085 [PREPRINT, MANUAL]** — CoVE: Towards Confidential Computing on RISC-V Platforms — Ravi Sahita; Atish Patra; Vedvyas Shanbhogue; Samuel Ortiz; Andrew Bresticker; Dylan Reid; Atul Khare; Rajnesh Kanwal (2023). arXiv (Cornell University). https://doi.org/10.48550/arxiv.2304.06167
- **F0086 [PREPRINT]** — ACE: Confidential Computing for Embedded RISC-V Systems — Wojciech Ozga; Guerney D. H. Hunt; Michael Le; Lennard Gäher; Avraham Shinnar; Elaine R. Palmer; Hani Jamjoom; Silvio Dragone (2025). arXiv (Cornell University). https://doi.org/10.48550/arxiv.2505.12995
- **F0087 [LOCAL_PDF, RESTRICTED]** — Isadora — Calvin Deutschbein; Andres Meza; Francesco Restuccia; Ryan Kastner; Cynthia Sturton (2021). Proceedings of the 5th Workshop on Attacks and Solutions in Hardware Security. https://doi.org/10.1145/3474376.3487286
- **F0088** — Chunked-Cache: On-Demand and Scalable Cache Isolation for Security Architectures — Ghada Dessouky; Emmanuel Stapf; Pouya Mahmoody; Alexander Gruler; Ahmad‐Reza Sadeghi (2022). Proceedings 2022 Network and Distributed System Security Symposium. https://doi.org/10.14722/ndss.2022.23110
- **F0089** — CrossTalk: Speculative Data Leaks Across Cores Are Real — Hany Ragab; Alyssa Milburn; Kaveh Razavi; Herbert Bos; Cristiano Giuffrida (2021). 2021 IEEE Symposium on Security and Privacy (SP). https://doi.org/10.1109/sp40001.2021.00020
- **F0090 [PREPRINT]** — An Enclave-based TEE for SE-in-SoC in RISC-V Industry — Xuanle Ren; Xiaoxia Cui (2022). arXiv (Cornell University). https://doi.org/10.48550/arxiv.2208.03631
- **F0091 [CORE]** — Aker: A Design and Verification Framework for Safe and Secure SoC Access Control — Francesco Restuccia; Andres Meza; Ryan Kastner (2021). 2021 IEEE/ACM International Conference On Computer Aided Design (ICCAD). https://doi.org/10.1109/iccad51958.2021.9643538
- **F0092 [CORRECTED]** — Securing access to and from devices in a RISC-V multicore architecture used for virtualization — Rieul Ducousso (2023). theses.fr (ABES). https://www.lip6.fr/actualite/personnes-fiche.php?ident=D2315
- **F0093 [CORE, CORRECTED]** — RISC-V IOPMP Architecture Specification — RISC-V International (2024). RISC-V International. https://github.com/riscv-non-isa/riscv-iopmp
- **F0094 [CORE, MANUAL]** — Enhancing configuration flexibility in an Open-Source RISC-V IOPMP IP — Luís Carlos da Costa e Cunha; Manuel J. Rodrı́guez; Sandro Pinto (2025). Portuguese National Funding Agency for Science, Research and Technology (RCAAP Project by FCT). https://hdl.handle.net/1822/101184
- **F0095 [PREPRINT]** — System-Level Isolation for Mixed-Criticality RISC-V SoCs: A "World" Reality Check — Luís Cunha; José Martins; Manuel Rodriguez; Tiago Gomes; Sandro Pinto; Uwe Moslehner; Kai Dieffenbach; Glenn Farrall; Kajetan Nuernberger; Thomas Roecker (2026). Open MIND. https://doi.org/10.48550/arxiv.2602.05002
- **F0096** — Security of Dynamically Reconfigurable RISC-V Systems: I/O Attack Focus — Aya Jendoubi; Jean-Christophe Prévotet; Tanguy Philippe; Pascal Cotret (2025). 2025 IEEE International Parallel and Distributed Processing Symposium Workshops (IPDPSW). https://doi.org/10.1109/ipdpsw66978.2025.00198
- **F0097 [CORE, MANUAL, CORRECTED]** — An open-source trusted execution environment for resource-constrained RISC-V MCUs — Luís Carlos da Costa e Cunha; Bruno Fernandes; Joao do Sousa; Tiago Gomes; Sandro Pinto (2025). Portuguese National Funding Agency for Science, Research and Technology (RCAAP Project by FCT). https://riscv-europe.org/summit/2025/media/proceedings/2025-05-14-RISC-V-Summit-Europe-P3.2.04-CUNHA-abstract.pdf

### 6. Key path, secure memory and trusted-code storage

- **F0098** — Integration of Hardware Security Modules and Permissioned Blockchain in Industrial IoT Networks — Antonio Cabrera; Encarnación Castillo; Antonio Escobar-Molero; José Antonio Álvarez Bermejo; Diego P. Morales; Luis Parrilla (2022). IEEE Access. https://doi.org/10.1109/access.2022.3217815
- **F0099** — Hardware Design of an Advanced-Feature Cryptographic Tile Within the European Processor Initiative — Pietro Nannipieri; Luca Crocetti; Stefano Di Matteo; Luca Fanucci; Sergio Saponara (2023). IEEE Transactions on Computers. https://doi.org/10.1109/tc.2023.3278536
- **F0100** — Key Extraction Using Thermal Laser Stimulation — Heiko Lohrke; Shahin Tajik; Thilo Krachenfels; Christian Boit; Jean‐Pierre Seifert (2018). IACR Transactions on Cryptographic Hardware and Embedded Systems. https://doi.org/10.46586/tches.v2018.i3.573-595
- **F0101** — TNPU: Supporting Trusted Execution with Tree-less Integrity Protection for Neural Processing Unit — Sunho Lee; Jung-Woo Kim; Seonjin Na; Jongse Park; Jaehyuk Huh (2022). 2022 IEEE International Symposium on High-Performance Computer Architecture (HPCA). https://doi.org/10.1109/hpca53966.2022.00025
- **F0102 [LOCAL_PDF, RESTRICTED]** — A comparison study of intel SGX and AMD memory encryption technology — Saeid Mofrad; Fengwei Zhang; Shiyong Lu; Weidong Shi (2018). Proceedings of the 7th International Workshop on Hardware and Architectural Support for Security and Privacy. https://doi.org/10.1145/3214292.3214301
- **F0103 [LOCAL_PDF, RESTRICTED]** — Blockchain and Secure Element, a Hybrid Approach for Secure Energy Smart Meter Gateways — Carine Zakaret; Nikolaos Peladarinos; Vasileios Cheimaras; Efthymios Tserepas; Panagiotis Papageorgas; Michel Aillerie; Dimitrios Piromalis; Kyriakos Agavanakis (2022). Sensors. https://doi.org/10.3390/s22249664
- **F0104** — Foreshadow: extracting the keys to the intel SGX kingdom with transient out-of-order execution — Jo Van Bulck; Marina Minkin; Ofir Weisse; Daniel Genkin; Baris Kasikci; Frank Piessens; Mark Silberstein; Thomas F. Wenisch; Yuval Yarom; Raoul Strackx (2018). Lirias. https://lirias.kuleuven.be/handle/123456789/626643
- **F0105** — The Evolution of Quantum Key Distribution Networks: On the Road to the Qinternet — Yuan Cao; Yongli Zhao; Qin Wang; Jie Zhang; Soon Xin Ng; Lajos Hanzo (2022). IEEE Communications Surveys & Tutorials. https://doi.org/10.1109/comst.2022.3144219
- **F0106 [CORE]** — OpenTitan Key Manager — OpenTitan contributors (2026). OpenTitan contributors. https://opentitan.org/earlgrey_1.0.0/book/hw/ip/keymgr/index.html
- **F0107 [CORE, LOCAL_PDF, RESTRICTED]** — SRAM has no chill: exploiting power domain separation to steal on-chip secrets — Jubayer Mahmod; Matthew Hicks (2022). Proceedings of the 27th ACM International Conference on Architectural Support for Programming Languages and Operating Systems. https://doi.org/10.1145/3503222.3507710
- **F0108** — VC3: Trustworthy Data Analytics in the Cloud Using SGX — Félix Schuster; Manuel Costa; Cédric Fournet; Christos Gkantsidis; Marcus Peinado; Gloria Mainar-Ruiz; Mark Russinovich (2015). 2015 IEEE Symposium on Security and Privacy. https://doi.org/10.1109/sp.2015.10
- **F0109** — RAMBleed: Reading Bits in Memory Without Accessing Them — Andrew Kwong; Daniel Genkin; Daniel Gruss; Yuval Yarom (2020). 2020 IEEE Symposium on Security and Privacy (SP). https://doi.org/10.1109/sp40000.2020.00020
- **F0110** — OpenTitan Identities and Root Keys — OpenTitan contributors (2026). OpenTitan contributors. https://opentitan.org/book/doc/security/specs/identities_and_root_keys/
- **F0111** — SMART: A Secure Magnetoelectric AntifeRromagnet-Based Tamper-Proof Non-Volatile Memory — Nikhil Rangarajan; Satwik Patnaik; Johann Knechtel; Ozgur Sinanoglu; Shaloo Rakheja (2020). IEEE Access. https://doi.org/10.1109/access.2020.2988889
- **F0112** — An Energy-Efficient Reconfigurable DTLS Cryptographic Engine for Securing Internet-of-Things Applications — Utsav Banerjee; Andrew Wright; Chiraag Juvekar; Madeleine Waller; Arvind Arvind; Anantha P. Chandrakasan (2019). IEEE Journal of Solid-State Circuits. https://doi.org/10.1109/jssc.2019.2915203
- **F0113** — Ginseng: Keeping Secrets in Registers When You Distrust the Operating System — Min Hong Yun; Lin Zhong (2019). Proceedings 2019 Network and Distributed System Security Symposium. https://doi.org/10.14722/ndss.2019.23327
- **F0114** — Physical Attack Protection Techniques for IC Chip Level Hardware Security — Makoto Nagata; Takuji Miki; Noriyuki Miura (2021). IEEE Transactions on Very Large Scale Integration (VLSI) Systems. https://doi.org/10.1109/tvlsi.2021.3073946
- **F0115** — Recommendation for Key Management Part 1: General — Elaine B. Barker (2016). National Institute of Standards and Technology. https://doi.org/10.6028/nist.sp.800-57pt1r4
- **F0116** — Analysis of Software Countermeasures for Whitebox Encryption — Subhadeep Banik; Andrey Bogdanov; Takanori Isobe; Martin Rudbeck Jepsen (2017). IACR Transactions on Symmetric Cryptology. https://doi.org/10.46586/tosc.v2017.i1.307-328
- **F0117** — Hardware Security Implications of Reliability, Remanence, and Recovery in Embedded Memory — Sergei Skorobogatov (2018). Journal of Hardware and Systems Security. https://doi.org/10.1007/s41635-018-0050-5
- **F0118** — A Secure Scan Architecture Protecting Scan Test and Scan Dump Using Skew-Based Lock and Key — Hyungil Woo; Seokjun Jang; Sungho Kang (2021). IEEE Access. https://doi.org/10.1109/access.2021.3097348
- **F0119** — A Secure and Authenticated Key Management Protocol (SA-KMP) for Vehicular Networks — Hengchuan Tan; Maode Ma; Houda Labiod; Aymen Boudguiga; Jun Zhang; Peter Han Joo Chong (2016). IEEE Transactions on Vehicular Technology. https://doi.org/10.1109/tvt.2016.2621354
- **F0120** — A Compact Hardware Implementation of CCA-Secure Key Exchange Mechanism CRYSTALS-KYBER on FPGA — Yufei Xing; Shuguo Li (2021). IACR Transactions on Cryptographic Hardware and Embedded Systems. https://doi.org/10.46586/tches.v2021.i2.328-356
- **F0121** — Exploiting Correcting Codes: On the Effectiveness of ECC Memory Against Rowhammer Attacks — Lucian Cojocar; Kaveh Razavi; Cristiano Giuffrida; Herbert Bos (2019). 2019 IEEE Symposium on Security and Privacy (SP). https://doi.org/10.1109/sp.2019.00089
- **F0122 [PREPRINT]** — A Lightweight Isolation Mechanism for Secure Branch Predictors — Lutan Zhao; Peinan Li; Rui Hou; Michael Huang; Jiazhen Li; Lixin Zhang; Xuehai Qian; Dan Meng (2020). arXiv (Cornell University). https://doi.org/10.48550/arxiv.2005.08183
- **F0123** — Recommendation for key management: — Elaine B. Barker (2020). National Institute of Standards and Technology. https://doi.org/10.6028/nist.sp.800-57pt1r5

### 7. Secure boot, attestation and hardware root of trust

- **F0124 [CORE, LOCAL_PDF, RESTRICTED]** — Unleashing OpenTitan’s Potential: a Silicon-Ready Embedded Secure Element for Root of Trust and Cryptographic Offloading — Maicol Ciani; Emanuele Parisi; Alberto Musa; Francesco Barchi; Andrea Bartolini; Ari Kulmala; Rafail Psiakis; Angelo Garofalo; Andrea Acquaviva; Davide Rossi (2024). ACM Transactions on Embedded Computing Systems. https://doi.org/10.1145/3690823
- **F0125 [CORE]** — Security Verification of the OpenTitan Hardware Root of Trust — Andres Meza; Francesco Restuccia; Jason Oberg; Dominic Rizzo; Ryan Kastner (2023). IEEE Security & Privacy. https://doi.org/10.1109/msec.2023.3251954
- **F0126 [CORE]** — BASTION: A Framework for Secure Third-Party IP Integration in NoC-based SoC Platforms — Francesco Restuccia; Zhenghua Ma; Joseph D. Zuckerman; Andres Meza; Biruk Seyoum; Luca P. Carloni; Ryan Kastner (2025). IACR Transactions on Cryptographic Hardware and Embedded Systems. https://doi.org/10.46586/tches.v2025.i4.317-340
- **F0127** — SYNFI: Pre-Silicon Fault Analysis of an Open-Source Secure Element — Pascal Nasahl; Miguel Osorio García de Oteyza; Pirmin Vogel; Michael Schaffner; Timothy Trippel; Dominic Rizzo; Stefan Mangard (2022). IACR Transactions on Cryptographic Hardware and Embedded Systems. https://doi.org/10.46586/tches.v2022.i4.56-87
- **F0128 [CORE]** — Fault Attacks on Access Control in Processors: Threat, Formal Analysis and Microarchitectural Mitigation — Anna Lena Duque Antón; Johannes Müller; Mohammad Rahmani Fadiheh; Dominik Stoffel; Wolfgang Kunz (2023). IEEE Access. https://doi.org/10.1109/access.2023.3280804
- **F0129** — Fault-Resistant Partitioning of Secure CPUs for System Co-Verification against Faults — Simon Tollec; Vedad Hadži ́c; Pascal Nasahl; Mihail Asăvoae; Roderick Bloem; Damien Couroussé; Karine Heydemann; Mathieu Jan; Stefan Mangard (2024). IACR Transactions on Cryptographic Hardware and Embedded Systems. https://doi.org/10.46586/tches.v2024.i4.179-204
- **F0130 [LOCAL_PDF, RESTRICTED]** — Trusted Heterogeneous Disaggregated Architectures — Atsushi Koshiba; Felix Gust; Julian Pritzi; Anjo Vahldiek-Oberwagner; Nuno Santos; Pramod Bhatotia (2023). Proceedings of the 14th ACM SIGOPS Asia-Pacific Workshop on Systems. https://doi.org/10.1145/3609510.3609812
- **F0131** — Fault Attacks on ECC Signature Verification — Kevin Schneider; Lukas Auer; Alexander Wagner (2025). IACR Transactions on Cryptographic Hardware and Embedded Systems. https://doi.org/10.46586/tches.v2025.i4.1010-1052
- **F0132 [LOCAL_PDF, RESTRICTED]** — Assessing the Performance of OpenTitan as Cryptographic Accelerator in Secure Open-Hardware System-on-Chips — Emanuele Parisi; Alberto Musa; Maicol Ciani; Francesco Barchi; Davide Rossi; Andrea Bartolini; Andrea Acquaviva (2024). Proceedings of the 21st ACM International Conference on Computing Frontiers. https://doi.org/10.1145/3649153.3649213
- **F0133** — Metis: An Integrated Morphing Engine CPU to Protect Against Side Channel Attacks — Francesco Antognazza; Alessandro Barenghi; Gerardo Pelosi (2021). IEEE Access. https://doi.org/10.1109/access.2021.3077977
- **F0134 [LOCAL_PDF, RESTRICTED]** — Modular Verification of Secure and Leakage-Free Systems: From Application Specification to Circuit-Level Implementation — Anish Athalye; Henry Corrigan-Gibbs; Frans Kaashoek; Joseph Tassarotti; Nickolai Zeldovich (2024). Proceedings of the ACM SIGOPS 30th Symposium on Operating Systems Principles. https://doi.org/10.1145/3694715.3695956
- **F0135 [PREPRINT]** — Unlocking Hardware Security Assurance: The Potential of LLMs — Xingyu Meng; Amisha Srivastava; A. Arunachalam; Avik Ray; Pedro Henrique Silva; Rafail Psiakis; Yiorgos Makris; Kanad Basu (2023). arXiv (Cornell University). https://doi.org/10.48550/arxiv.2308.11042
- **F0136 [LOCAL_PDF, RESTRICTED]** — Patching FPGAs: The Security Implications of Bitstream Modifications — Endres Puschner; Maik Ender; Steffen Becker; Christof Paar (2024). Proceedings of the 2024 Workshop on Attacks and Solutions in Hardware Security. https://doi.org/10.1145/3689939.3695779
- **F0137** — Cyber Security aboard Micro Aerial Vehicles: An OpenTitan-based Visual Communication Use Case — Maicol Ciani; Stefano Bonato; Rafail Psiakis; Angelo Garofalo; Luca Valente; Suresh Sugumar; Alessandro Giusti; Davide Rossi; Daniele Palossi (2023). 2023 IEEE International Symposium on Circuits and Systems (ISCAS). https://doi.org/10.1109/iscas46773.2023.10181732
- **F0138 [PREPRINT]** — Information Flow Coverage Metrics for Hardware Security Verification — Andres Meza; Ryan Kastner (2023). arXiv (Cornell University). https://doi.org/10.48550/arxiv.2304.08263
- **F0139** — An FPGA-Based Open-Source Hardware-Software Framework for Side-Channel Security Research — Davide Zoni; Andrea Galimberti; Davide Galli (2025). IEEE Transactions on Computers. https://doi.org/10.1109/tc.2025.3551936
- **F0140** — Randomness Generation for Secure Hardware Masking – Unrolled Trivium to the Rescue — Gaëtan Cassiers; Loïc Masure; Charles Momin; Thorben Moos; Amir Moradi; François‐Xavier Standaert (2024). IACR Communications in Cryptology. https://doi.org/10.62056/akdkp2fgx
- **F0141 [LOCAL_PDF, RESTRICTED]** — SCRAMBLE-CFI: Mitigating Fault-Induced Control-Flow Attacks on OpenTitan — Pascal Nasahl; Stefan Mangard (2023). Proceedings of the Great Lakes Symposium on VLSI 2023. https://doi.org/10.1145/3583781.3590221
- **F0142** — DANA Universal Dataflow Analysis for Gate-Level Netlist Reverse Engineering — Nils Albartus; Max Hoffmann; Sebastian Temme; Leonid Azriel; Christof Paar (2020). IACR Transactions on Cryptographic Hardware and Embedded Systems. https://doi.org/10.46586/tches.v2020.i4.309-336
- **F0143 [PREPRINT]** — (Security) Assertions by Large Language Models — Rahul Kande; Hammond Pearce; Benjamin Tan; Brendan Dolan-Gavitt; Shailja Thakur; Ramesh Karri; Jeyavijayan Rajendran (2023). arXiv (Cornell University). https://doi.org/10.48550/arxiv.2306.14027
- **F0144 [PREPRINT]** — FVCARE:Formal Verification of Security Primitives in Resilient Embedded SoCs — Avani Dave; Nilanjan Banerjee; Chintan Patel (2023). arXiv (Cornell University). https://doi.org/10.48550/arxiv.2304.11489
- **F0145** — Open Source Hardware Design and Hardware Reverse Engineering: A Security Analysis — Johanna Baehr; Alexander Hepp; Michaela Brunner; Maja Malenko; Georg Sigl (2022). 2022 25th Euromicro Conference on Digital System Design (DSD). https://doi.org/10.1109/dsd57027.2022.00073
- **F0146** — Quantum-Resilient Cloud Systems: Preemptive Shielding Against Post-Quantum Cryptographic Threats — Naga Subrahmanyam Cherukupalle (2025). Journal of Information Systems Engineering & Management. https://doi.org/10.52783/jisem.v10i38s.8781
- **F0147 [PUBLISHED_UPDATE]** — Fuzzing Hardware Like Software — Timothy Trippel; Kang G. Shin; Alex Chernyakhovsky; Garret Kelly; Dominic Rizzo; Matthew Hicks (2022). 31st USENIX Security Symposium (USENIX Security 22). https://www.usenix.org/conference/usenixsecurity22/presentation/trippel
- **F0148** — Vérification formelle de la micro-architecture de processeurs pour l'analyse de sécurité des systèmes contre les attaques par injection de fautes — Simon Tollec (2024). HAL (Le Centre pour la Communication Scientifique Directe). https://theses.hal.science/tel-04845491

### 8. Debug lockdown, lifecycle control and secret zeroization

- **F0149** — IoTrust - a HW/SW framework supporting security core baseline features for IoT — Mateusz Korona; Bartosz Zabołotny; Fryderyk Kozioł; Mateusz Biernacki; Radosław Giermakowski; Paweł Rurka; Marta Chmiel; Mariusz Rawski (2023). Annals of Computer Science and Information Systems. https://doi.org/10.15439/2023f6946
- **F0150 [LOCAL_PDF, RESTRICTED]** — Secure Instruction and Data-Level Information Flow Tracking Model for RISC-V — Geraldine Shirley Nicholas; Dhruvakumar Vikas Aklekar; Bhavin Thakar; Fareena Saqib (2023). Cryptography. https://doi.org/10.3390/cryptography7040058
- **F0151** — OpenTitan Big Number Accelerator (OTBN) — OpenTitan contributors (2026). OpenTitan contributors. https://opentitan.org/book/hw/ip/otbn/index.html
- **F0152** — Practical challenges in quantum key distribution — Eleni Diamanti; Hoi-Kwong Lo; Bing Qi; Zhiliang Yuan (2016). npj Quantum Information. https://doi.org/10.1038/npjqi.2016.25
- **F0153** — TRUSTPUF - A Resilient FPGA RO-PUF for Secure Authentication — K M Inchara; Meghana Kulkarni; Prashant Dhope (2025). Journal of Emerging Technologies and Innovative Research. https://doi.org/10.56975/jetir.v12i9.569517
- **F0154** — Secure boot, trusted boot and remote attestation for ARM TrustZone-based IoT Nodes — Zhen Ling; Huaiyu Yan; Xinhui Shao; Junzhou Luo; Yiling Xu; Bryan Pearson; Xinwen Fu (2021). Journal of Systems Architecture. https://doi.org/10.1016/j.sysarc.2021.102240
- **F0155** — Test Versus Security: Past and Present — Jean Da Rolt; A. Das; Giorgio Di Natale; Marie-Lise Flottes; Bruno Rouzeyre; Ingrid Verbauwhede (2014). IEEE Transactions on Emerging Topics in Computing. https://doi.org/10.1109/tetc.2014.2304492
- **F0156** — Verilog Design of Programmable JTAG Controller for Digital VLSI IC’s — Ramesh Bhakthavatchalu; Saranya K. Kannan; M. Nirmala Devi (2015). Indian Journal of Science and Technology. https://doi.org/10.17485/ijst/2015/v8i17/62664
- **F0157** — A Learning-Based Approach to Secure JTAG Against Unseen Scan-Based Attacks — Xuanle Ren; R.D. Blanton; Vítor Grade Tavares (2016). 2016 IEEE Computer Society Annual Symposium on VLSI (ISVLSI). https://doi.org/10.1109/isvlsi.2016.107
- **F0158** — A Secure DFT Architecture Protecting Crypto Chips Against Scan-Based Attacks — Weizheng Wang; Jincheng Wang; Wei Wang; Peng Liu; Shuo Cai (2019). IEEE Access. https://doi.org/10.1109/access.2019.2898447
- **F0159 [PREPRINT, MANUAL, CORRECTED]** — ATLAS: AI-Assisted Threat-to-Assertion Learning for System-on-Chip Security Verification — Ishraq Tashdid; Kimia Tasnia; Alexander Garcia; Jonathan Valamehr; Sazadur Rahman (2026). arXiv (Cornell University). https://arxiv.org/abs/2603.01170
- **F0160** — libmpk: Software Abstraction for Intel Memory Protection Keys (Intel MPK). — Soyeon Park; Sangho Lee; Wen Xu; Hyungon Moon; Taesoo Kim (2019). Scholarworks@UNIST (Ulsan National Institute of Science and Technology). https://scholarworks.unist.ac.kr/handle/201301/33417
- **F0161** — SASL-JTAG+: An Enhanced Lightweight and Secure JTAG Authentication Mechanism for IoT Systems with Diverse Devices — Hisashi Okamoto; Shaoqi Wei; Senling Wang; Hiroshi Kai; Hiroshi Takahashi; Yoshinobu Higami; A. Shimizu; Tianming Ni; Xiaoqing Wen (2025). Journal of Communications. https://doi.org/10.12720/jcm.20.2.214-220
- **F0162 [CORE, MANUAL]** — ZeroTrace: Provable Storage Sanitisation Through Modular Erasure Engines and Cryptographic Audit Attestation — Gaurav Salunke; Krishna Pandey; Esha Gholap; Prof.  Prachi Bhure (2026). Open MIND. https://doi.org/10.5281/zenodo.19511539

### 9. Boundary attacks, assurance and formal verification

- **F0163** — Plundervolt: Software-based Fault Injection Attacks against Intel SGX — Kit Murdock; David Oswald; Flavio D. Garcia; Jo Van Bulck; Daniel Gruss; Frank Piessens (2020). 2020 IEEE Symposium on Security and Privacy (SP). https://doi.org/10.1109/sp40000.2020.00057
- **F0164** — SIFA: Exploiting Ineffective Fault Inductions on Symmetric Cryptography — Christoph Dobraunig; Maria Eichlseder; Thomas Korak; Stefan Mangard; Florian Mendel; Robert Primas (2018). IACR Transactions on Cryptographic Hardware and Embedded Systems. https://doi.org/10.46586/tches.v2018.i3.547-572
- **F0165** — VoltPillager: Hardware-based fault injection attacks against Intel {SGX} Enclaves using the {SVID} voltage scaling interface — Zitai Chen; Georgios Vasilakis; Kit Murdock; Edward Dean; David Oswald; Flavio D. Garcia (2021). University of Birmingham Research Portal (University of Birmingham). https://research.birmingham.ac.uk/en/publications/bfe72039-6623-4dff-ac9d-22a45a261ac8
- **F0166** — Chypnosis: Undervolting-based Static Side-channel Attacks — Kyle Mitard; Saleh Khalaj Monfared; Fatemeh Khojasteh Dana; Robert Dumitru; Yuval Yarom; Shahin Tajik (2026). 2026 IEEE Symposium on Security and Privacy (SP). https://doi.org/10.1109/sp63933.2026.00090
- **F0167** — Shaping the Glitch: Optimizing Voltage Fault Injection Attacks — Claudio Bozzato; Riccardo Focardi; Francesco Palmarini (2019). IACR Transactions on Cryptographic Hardware and Embedded Systems. https://doi.org/10.46586/tches.v2019.i2.199-224
- **F0168** — Fault Injection as an Oscilloscope: Fault Correlation Analysis — Albert Spruyt; Alyssa Milburn; Łukasz Chmielewski (2020). IACR Transactions on Cryptographic Hardware and Embedded Systems. https://doi.org/10.46586/tches.v2021.i1.192-216
- **F0169** — How Practical Are Fault Injection Attacks, Really? — Jakub Breier; Xiaolu Hou (2022). IEEE Access. https://doi.org/10.1109/access.2022.3217212
- **F0170** — A Multi-Layer Hardware Trojan Protection Framework for IoT Chips — Chen Dong; Guorong He; Ximeng Liu; Yang Yang; Wenzhong Guo (2019). IEEE Access. https://doi.org/10.1109/access.2019.2896479
- **F0171** — Fly Away: Lifting Fault Security through Canaries and the Uniform Random Fault Model — Gaëtan Cassiers; Siemen Dhooghe; Thorben Moos; Sayandeep Saha; François‐Xavier Standaert (2025). IACR Communications in Cryptology. https://doi.org/10.62056/an-49qxqi
- **F0172** — CRAFT: Lightweight Tweakable Block Cipher with Efficient Protection Against DFA Attacks — Christof Beierle; Gregor Leander; Amir Moradi; Shahram Rasoolzadeh (2019). IACR Transactions on Symmetric Cryptology. https://doi.org/10.46586/tosc.v2019.i1.5-45
- **F0173 [CORE]** — OpenTitan Register Tool — Shadowed Registers — OpenTitan contributors (2026). OpenTitan contributors. https://opentitan.org/book/util/reggen/index.html
- **F0174** — Fill your Boots: Enhanced Embedded Bootloader Exploits via Fault Injection and Binary Analysis — Jan Van den Herrewegen; David Oswald; Flavio D. Garcia; Qais Temeiza (2020). IACR Transactions on Cryptographic Hardware and Embedded Systems. https://doi.org/10.46586/tches.v2021.i1.56-81
- **F0175** — FIVER – Robust Verification of Countermeasures against Fault Injections — Jan Richter-Brockmann; Aein Rezaei Shahmirzadi; Pascal Sasdrich; Amir Moradi; Tim Güneysu (2021). IACR Transactions on Cryptographic Hardware and Embedded Systems. https://doi.org/10.46586/tches.v2021.i4.447-473

### 10. Reference isolation model and design trade-offs

- **F0176 [CORE]** — OpenTitan OTP Controller — Theory of Operation — OpenTitan contributors (2026). OpenTitan contributors. https://opentitan.org/book/hw/ip/otp_ctrl/doc/theory_of_operation.html
- **F0177 [CORE]** — OpenTitan Lifecycle Controller — Theory of Operation — OpenTitan contributors (2026). OpenTitan contributors. https://opentitan.org/book/hw/ip/lc_ctrl/doc/theory_of_operation.html
- **F0178** — RISC-V Security Model — Chapter 3 — RISC-V International (2026). RISC-V International. https://github.com/riscv-non-isa/riscv-security-model/blob/main/specification/src/chapter3.adoc
- **F0179 [CORE]** — OpenTitan Security Documentation — OpenTitan contributors (2026). OpenTitan contributors. https://opentitan.org/book/doc/security/
- **F0180 [CORE]** — OpenTitan Access Range Check — OpenTitan contributors (2026). OpenTitan contributors. https://opentitan.org/book/hw/top_darjeeling/ip_autogen/ac_range_check/index.html

## 10. Итоговая рабочая стратегия

1. Воспринимать базу как стартовую карту поля, а не как подтверждение заранее выбранной темы.
2. Начать с обзоров, нормативных материалов и стартового ядра, затем перейти к первичным работам.
3. Построить собственную матрицу сравнений и зафиксировать ограничения каждой работы.
4. Сформулировать 3–5 кандидатов научного пробела и проверить каждый дополнительным поиском и анализом цитирований.
5. Для каждого жизнеспособного пробела предложить тему, научный вопрос, вклад, метод проверки, необходимые ресурсы и риски.
6. Выбрать тему по совокупности новизны, значимости, выполнимости и соответствия проекту, а не только по количеству найденных публикаций.
7. Только после выбора темы сформировать рабочее ядро из 30–50 источников и расширенный библиографический пул.
8. Перед написанием статьи повторно проверить ближайшие аналоги, актуальность DOI/URL, версии публикаций и свежие работы, вышедшие после формирования базы.
