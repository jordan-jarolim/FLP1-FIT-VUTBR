FLP 1st Project
Jordan Jarolim, xjarol03, FIT VUTBR
1. 4. 2017
README.md
 
- Toto je README.md soubor k popisu mého řešení prvního projektu do předmětu FLP v roce 2016/2017, zadání subs-cipher.

----------------------------------

IMPLEMENTOVANÉ ŘEŠENÍ:
Mnou implementovaný algoritmus využívá pro nalezení kliče jak frekvence jednotlivých písmen, tak frekvence digramů i trigramů. 

V prvním kroce program zpracuje vstupní argumenty. Na základě argumentů načte soubor databáze, roztřídí jednotlivé řádky dle délky řetězce (roztřízení na písmena, digramy a trigramy) a seřadí písmena, bigramy a trigramy zvlášť dle frekvence. Dále si načte vstupní soubor (ať už se jedná o soubor nebo o stdin). Pro získání prvního a nejjednoduššího klíče, založeného pouze na frekvenční analýze jednotlivých pímsen, spočítá program výskyt jednotlivých písmen ve vstupním soboru a seřadí je dle četnosti. Tím získá první výchozí klíč. 

Dalším krokem je získání klíče na základě četnosti digramů. Program si uloží všechny možné vyskytující digramy do pole - pro text "abcdab" tedy uloží bigramy ab, bc, cd, da, ab. Seřadí je dle četnosi. Na příkladu vidíme, že "ab" se vyskytuje nejvíckrát. Takto seřazené bigramy porovná s databází následovně:
Zpracovává digram "ab" - jedná se o nejčetnější digram - z databáze vezme také nejčetnější digram, např "th" a pokusí se namapovat "ab" -> "th". Mapování probíhá tak, že pro každé písmeno se podívá, jakou pozici má v seznamu single letters v databázi a na tuto pozici uloží písmeno z digramu. Zpracuje tedy "a", zjistí, že se má mapovat na "t", to je v databázi jednotlivých písmen na druhé pozici. Symbol "a" tedy uloží do výsledného klíče také na druhou pozici. Písmeno "b" namapuje na "h", dle databáze tedy na 8 pozici. Takto postupně projde všechny digramy a vytvoří klíč. Pokud je při tvorbě klíče nalezeno písmeno, které již v klíči je, program jej přeskočí. Stejně tak udělá, pokud se nějaké písmeno mapuje např na "l" z databáze a v průběhu by se na "l" mělo namapovat něco jiného. Jelikož program postupuje z nejčetnějších digramů směrem k tém méně četným, digramy zpracovávané ze začátku mají největší pravděpodonost výskytu - největší pravděpodobnost, že byly namapovány správně. Pokud pro nějaký symbol neexistuje v klíči z digramů mapování, je toto prázdné místo vyplněno nevalidními symboly, např "1", aby zůstalo zachováné pořadí vzhledem k databázi.

Tvoření klíče pro trigramy funguje naprosto srovnatelně s digramy. Pro text "abcdeabc" získá program trigramy abc, bcd, cde, dea, eab, abc. Opět je seřadí a postupuje shodně s popisem výše.

Na závěr program tyto klíče zkombinuje dohromady. Na pozicích, kde se shodují klíče pro single letters, bigramy i trigramy, je to jasné, symbol se umístí do klíče. Na pozicích, kde se shodují 2/3, je do klíče umístěn převažující symbol. Na místech, kde jsou tři různé symboly, je umístěn symbol z klíče pro trigramy. Při tomto kombinování se musí také brát v potaz, že se klíče mohou shodovat v místech, kde žádné symboly neobsahují a mají tam jen výplně ("1"). Takové symboly jsou samozřejmě přeskočeny. Pokud by měl program do výsledného klíče umístit symbol z klíče trigramů, ale byla tam "1", program se podívá na symbol v klíči bigramů, pokud i tam je "1", zapíše symbol z klíče pro single letter. Stejně progam přeskakuje i ty symboly, které se již v klíči nacházejí. 

Rozšifrování textu probíhá pomocí mapování klíče na symboly v databázi tak, jak jsou tam postupně umístěny. Tedy pokud jsou první tři symboly klíče "dlm" a v databázi "eta" v textu se ze všech "d" stanou "e", ze všech "l" se stanou "t" a tak dále.

----------------------------------

ROZŠÍŘENÍ:

Než jsem došel k řešení popsanému výše, pokusil jsem se naprogramovat genetický algoritmus, který by se postupnými iteracemi dopracoval k přesnému klíči. Inspirací mi byl algoritmus popsaný zde: http://practicalcryptography.com/cryptanalysis/stochastic-searching/cryptanalysis-simple-substitution-cipher/

Metoda funguje tak, že si zvolí na začátku parent klíč (náhodný nebo klíč na základě frekvenční analýzy jednotlivých písmen), text rozšifruje a na základě digramů a trigramů z databáze spočítá fitness funkci = podobnost rozšifrovaného textu a anglickým textem. Poté náhodně prohodí dva symboly klíče, spočítá fitness funkci a pokud vyjde vyšší podobnost, uloži si tento klíč jako nový parent, ve kterém v dalším kroku opět prohodí dva symboly. Pokud vyjde fitness stejná nebo nižší, neukládá si nový parent, ale prohazuje v původním. Jakmile 1000x nedojde k aktualizaci parent klíče, je tento klíč považován za výsledný. 

Bohužel, tento algoritmus nevedl k požadované přesnosti a je velmi pomalý. Proto je pouze zmíněn ze zajímavosti. Lze však spustit přepínačem -f na první pozici, např: ./subs-cipher -f -t english.db test.in
Parametr -f je volitelný, je možné jej zadat v kombinaci s parametrem -t, ten vypíše na výstup rozšifrovaný text.

----------------------------------

SHRNUTÍ VÝSLEDKŮ:

Pro testovací vstup je po rozšifrování za pomocí single letters, digramů a trigramů podobnost s referenčním výstupem cca 65.481%. Při použití pouze klíče pro single letters je podobnost jen 25.465%. Použití genetického algoritmu dojde k podobnosti mezi 0% - 10%.

Nejlepších výsledků je tedy jednoznačně dosažeo při kombinací klíčů pro single letters, digramy a trigramy.

