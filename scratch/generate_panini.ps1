# Generate paniniwc2026.json
$categories = @()
$pages = @()
$stickers = @()

# Category 1: Intro
$categories += @{id=1; name="Host Countries & Cities"; badgeAssetId=0}
$pages += @{page=1; categoryId=1; layout="grid_9"}
$intro = @("00|Panini Logo","FWC1|Official Emblem","FWC2|Official Emblem","FWC3|Official Mascots","FWC4|Official Slogan","FWC5|Official Ball","FWC6|Canada","FWC7|Mexico","FWC8|USA")
foreach ($s in $intro) {
    $parts = $s -split '\|'
    $stickers += @{id=$parts[0]; name=$parts[1]; page=1; categoryId=1}
}

# Country data: PREFIX|Name|p2|p3|p4|p5|p6|p7|p8|p9|p10|p11|p12|p14|p15|p16|p17|p18|p19|p20
$countryData = @(
"MEX|Mexico|Luis Malagon|Johan Vasquez|Jorge Sanchez|Cesar Montes|Jesus Gallardo|Israel Reyes|Diego Lainez|Carlos Rodriguez|Edson Alvarez|Orbelin Pineda|Marcel Ruiz|Erick Sanchez|Hirving Lozano|Santiago Gimenez|Raul Jimenez|Alexis Vega|Roberto Alvarado|Cesar Huerta"
"RSA|South Africa|Ronwen Williams|Sipho Chaine|Aubrey Modiba|Samukele Kabini|Mbekezeli Mbokazi|Khulumani Ndamane|Siyabonga Ngezana|Khuliso Mudau|Nkosinathi Sibisi|Teboho Mokoena|Thalente Mbatha|Bathasi Aubaas|Yaya Sithole|Sipho Mbule|Lyle Foster|Iqraam Rayners|Mohau Nkota|Oswin Appollis"
"KOR|South Korea|Hyeon-woo Jo|Seung-Gyu Kim|Min-jae Kim|Yu-min Cho|Young-woo Seol|Han-beom Lee|Tae-seok Lee|Myung-jae Lee|Jae-sung Lee|In-beom Hwang|Kang-in Lee|Seung-ho Paik|Jens Castrop|Dongg-yeong Lee|Gue-sung Cho|Heung-min Son|Hee-chan Hwang|Hyeon-Gyu Oh"
"CZE|Czechia|Matej Kovar|Jindrich Stanek|Ladislav Krejci|Vladimir Coufal|Jaroslav Zeleny|Tomas Holes|David Zima|Michal Sadilek|Lukas Provod|Lukas Cerv|Tomas Soucek|Pavel Sulc|Matej Vydra|Vasil Kusej|Tomas Chory|Vaclav Cerny|Adam Hlozek|Patrik Schick"
"CAN|Canada|Dayne St.Clair|Alphonso Davies|Alistair Johnston|Samuel Adekugbe|Riche Larvea|Derek Cornelius|Moise Bombito|Kamal Miller|Stephen Eustaquio|Ismael Kone|Jonathan Osorio|Jacob Shaffelburg|Mathieu Choiniere|Niko Sigur|Tajon Buchanan|Liam Millar|Cyle Larin|Jonathan David"
"BIH|Bosnia and Herzegovina|Nikola Vasilj|Amer Dedic|Sead Kolasinac|Tarik Muharemovic|Nihad Mujakic|Nikola Katic|Amir Hadziahmetovic|Benjamin Tahirovic|Armin Gigovic|Ivan Sunjic|Ivan Basic|Dzenis Burnic|Esmir Bajraktarevic|Amar Memic|Ermedin Demirovic|Edin Dzeko|Samed Bazdar|Haris Tabakovic"
"QAT|Qatar|Meshaal Barsham|Sultan Albrake|Lucas Mendes|Homam Ahmed|Boualem Khoukhi|Pedro Miguel|Tarek Salman|Mohamed Al-Mannai|Karim Boudiaf|Assim Madibo|Ahmed Fatehi|Mohammed Waad|Abdulaziz Hatem|Hassan Al-Haydos|Edmilson Junior|Akram Hassan Afif|Ahmed Al Ganehi|Almoez Ali"
"SUI|Switzerland|Gregor Kobel|Yvon Mvogo|Manuel Akanji|Ricardo Rodriguez|Nico Elvedi|Aurele Amenda|Silvan Widmer|Granit Xhaka|Denis Zakaria|Remo Freuler|Fabian Rieder|Ardon Jashari|Johan Manzambi|Michel Aebischer|Breel Embolo|Ruben Vargas|Dan Ndoye|Zeki Amdouni"
"BRA|Brazil|Alisson|Bento|Marquinhos|Eder Militao|Gabriel Magalhaes|Danilo|Wesley|Lucas Paqueta|Casemiro|Bruno Guimaraes|Luiz Henrique|Vinicius Junior|Rodrygo|Joao Pedro|Matheus Cunha|Gabriel Martinelli|Raphinha|Estevao"
"MAR|Morocco|Yassine Bounou|Munir El Kajoui|Achraf Hakimi|Noussair Mazraoui|Nayef Aguerd|Roman Saiss|Jawad El Yamio|Adam Masina|Sofyan Amrabat|Azzedine Ounahi|Eliesse Ben Seghir|Bilal El Khannouss|Ismael Saibari|Youssef En-Nesyri|Abde Ezzalzouli|Soufiane Rahimi|Brahim Diaz|Ayoub El Kaabi"
"HAI|Haiti|Johny Placide|Carlens Arcus|Martin Experience|Jean-Kevin Duverne|Ricardo Ade|Duke Lacroix|Garven Metusala|Hannes Delcroix|Leverton Pierre|Danley Jean Jacques|Jean-Ricner Bellegarde|Christopher Attys|Derrick Etienne Jr|Josue Casimir|Ruben Providence|Duckens Nazon|Louicius Deedson|Frantzdy Pierrot"
"SCO|Scotland|Angus Gunn|Jack Hendry|Kieran Tierney|Aaron Hickey|Andrew Robertson|Scott McKenna|John Souttar|Anthony Ralston|Grant Hanley|Scott McTominay|Billy Gilmour|Lewis Ferguson|Ryan Christie|Kenny McLean|John McGinn|Lyndon Dykes|Che Adams|Ben Gannon-Doak"
"USA|USA|Math Freese|Chris Richards|Tim Ream|Mark McKenzie|Alex Freeman|Antonee Robinson|Tyler Adams|Tanner Tessmann|Weston McKenny|Christian Roldan|Timothy Weah|Diego Luna|Malik Tillman|Christian Pulisic|Brenden Aaronson|Ricardo Pepi|Haji Wright|Folarin Balogun"
"PAR|Paraguay|Roberto Fernandez|Orlando Gill|Gustavo Gomez|Fabian Balbuena|Juan Jose Caceres|Omar Alderete|Junior Alonso|Mathias Villasanti|Diego Gomez|Damian Bobadilla|Andres Cubas|Matias Galarza Fonda|Julio Enciso|Alejandro Romero Gamarra|Miguel Almiron|Ramon Sosa|Angel Romero|Antonio Sanabria"
"AUS|Australia|Mathew Ryan|Joe Gauci|Harry Souttar|Alessandro Circati|Jordan Bos|Aziz Behich|Cameron Burgess|Lewis Miller|Milos Degenek|Jackson Irvine|Riley McGree|Aiden O'Neill|Connor Metcalfe|Patrick Yazbek|Craig Goodwin|Kusini Vengi|Nestory Irankunda|Mohamed Toure"
"TUR|Turkiye|Ugurcan Cakir|Mert Muldur|Zeki Celik|Abdulkerim Bardakci|Caglar Soyuncu|Merih Demiral|Ferdi Kadioglu|Kaan Ayhan|Ismail Yuksek|Hakan Calhanoglu|Orkun Kokcu|Arda Guler|Irfan Can Kahveci|Yunus Akgun|Can Uzun|Baris Alper Yilmaz|Kerem Akturkoglu|Kenan Yildiz"
"GER|Germany|Marc-Andre ter Stegen|Jonathan Tah|David Raum|Nico Schlotterbeck|Antonio Rudiger|Waldemar Anton|Ridle Baku|Maximilian Mittelstadt|Joshua Kimmich|Florian Wirtz|Felix Nmecha|Leon Goretzka|Jamal Musiala|Serge Gnabry|Kai Havertz|Leroy Sane|Karim Adeyemi|Nick Woltemade"
"CUW|Curacao|Eloy Room|Armando Obispo|Sherel Floranus|Jurien Gaari|Joshua Brenet|Roshon Van Eijma|Shurandy Sambo|Livano Comenencia|Godfried Roemeratoe|Juninho Bacuna|Leandro Bacuna|Tahith Chong|Kenji Gorre|Jearl Margaritha|Jurgen Locadia|Jeremy Antonisse|Gervane Kastaneer|Sontje Hansen"
"CIV|Ivory Coast|Yahia Fofana|Ghislain Konan|Wilfried Singo|Odilon Kossounou|Evan Ndicka|Willy Boly|Emmanuel Agbadou|Ousmane Diomande|Franck Kessie|Seko Fofana|Ibrahim Sangare|Jean-Philippe Gbamin|Amad Diallo|Sebastien Haller|Simon Adingra|Yan Diomande|Evann Guessand|Oumar Diakite"
"ECU|Ecuador|Hernan Galindez|Gonzalo Valle|Piero Hincapie|Pervis Estupinan|Willian Pacho|Angelo Preciado|Joel Ordonez|Moises Caicedo|Alan Franco|Kendry Paez|Pedro Vite|John Veboah|Leonardo Campana|Gonzalo Plata|Nilson Angulo|Alan Minda|Kevin Rodriguez|Enner Valencia"
"NED|Netherlands|Bart Verbruggen|Virgil van Dijk|Micky van de Ven|Jurrien Timber|Denzel Dumfries|Nathan Ake|Jeremie Frimpong|Jan Paul van Hecke|Tijjani Reijnders|Ryan Gravenberch|Teun Koopmeiners|Frenkie de Jong|Xavi Simons|Justin Kluivert|Memphis Depay|Donyell Malen|Wout Weghorst|Cody Gakpo"
"JPN|Japan|Zion Suzuki|Henry Heroki Mochizuki|Ayumu Seko|Junnosuke Suzuki|Shogo Taniguchi|Tsuyoshi Watanabe|Kaishu Sano|Yuki Soma|Ao Tanaka|Daichi Kamada|Takefusa Kubo|Ritsu Doan|Keito Nakamura|Takumi Minamino|Shuto Machino|Junya Ito|Koki Ogawa|Ayase Ueda"
"SWE|Sweden|Victor Johansson|Isak Hien|Gabriel Gudmundsson|Emil Holm|Victor Nilsson Lindelof|Gustaf Lagerbielke|Lucas Bergvall|Hugo Larsson|Jesper Karlstrom|Yasin Ayari|Mattias Svanberg|Daniel Svensson|Ken Sema|Roony Bardghji|Dejan Kulusevski|Anthony Elanga|Alexander Isak|Viktor Gyokeres"
"TUN|Tunisia|Bechir Ben Said|Aymen Dahmen|Yan Valery|Montassar Talbi|Yassine Meriah|Ali Abdi|Dylan Bronn|Ellyes Skhiri|Aissa Laidouni|Ferjani Sassi|Mohamed Ali Ben Romdhane|Hannibal Mejbri|Elias Achouri|Elias Saad|Hazem Mastouri|Ismael Gharbi|Sayfallah Ltaief|Naim Sliti"
"BEL|Belgium|Thibaut Courtois|Arthur Theate|Timothy Castagne|Zeno Debast|Brandon Mechele|Maxim De Cuyper|Thomas Meunier|Youri Tielemans|Amadou Onana|Nicolas Raskin|Alexis Saelemaekers|Hans Vanaken|Kevin De Bruyne|Jeremy Doku|Charles De Ketelaere|Leandro Trossard|Lois Openda|Romelu Lukaku"
"EGY|Egypt|Mohamed El Shenawy|Mohamed Hany|Mohamed Hamdy|Yasser Ibrahim|Khaled Sobhi|Ramy Rabia|Hossam Abdelmaguid|Ahmed Fatouh|Marwan Attia|Zizo|Hamdy Fathy|Mohamed Lasheen|Emam Ashour|Osama Faisal|Mohamed Salah|Mostafa Mohamed|Trezeguet|Omar Marmoush"
"IRN|Iran|Alireza Beiranvand|Morteza Pouraliganji|Ehsan Hajsafi|Milad Mohammadi|Shojae Khalilzadeh|Ramin Rezaeian|Hossein Kanaani|Sadegh Moharrami|Saleh Hardani|Saeed Ezatolahi|Saman Ghoddos|Omid Noorafkan|Roozbeh Cheshmi|Mohammad Mohebi|Sardar Azmoun|Mehdi Taremi|Alireza Jahanbakhsh|Ali Gholizadeh"
"NZL|New Zealand|Max Crocombe Payne|Alex Paulsen|Michael Boxall|Liberato Cacace|Tim Payne|Tyler Bindon|Francis de Vries|Finn Surman|Joe Bell|Sarpreet Singh|Ryan Thomas|Matthew Garbett|Marko Stamenic|Ben Old|Chris Wood|Elijah Just|Callum McCowatt|Kosta Barbarouses"
"ESP|Spain|Unai Simon|Robin Le Normand|Aymeric Laporte|Dean Huijsen|Pedro Porro|Dani Carvajal|Marc Cucurella|Martin Zubimendi|Rodri|Pedri|Fabian Ruiz|Mikel Merino|Lamine Yamal|Dani Olmo|Nico Williams|Ferran Torres|Alvaro Morata|Mikel Oyarzabal"
"CPV|Cape Verde|Vozinha|Logan Costa|Pico|Diney|Steven Moreira|Wagner Pina|Joao Paulo|Yannick Semedo|Kevin Pina|Patrick Andrade|Jamiro Monteiro|Deroy Duarte|Garry Rodrigues|Jovane Cabral|Ryan Mendes|Dailon Livramento|Willy Semedo|Bebe"
"KSA|Saudi Arabia|Nawaf Alaqidi|Abdulrahman Al-Sanbi|Saud Abdulhamid|Nawaf Bouwashl|Jihad Thakri|Moteb Al-Harbi|Hassan Altambakti|Musab Aljuwayr|Ziyad Aljohani|Abdullah Alkhaibari|Nasser Aldawsari|Saleh Abu Alshamat|Marwan Alsahafi|Salem Aldawsari|Abdulrahman Al-Aboud|Feras Akbrikan|Saleh Alshehri|Abdullah Al-Hamdan"
"URU|Uruguay|Sergio Rochet|Santiago Mele|Ronald Araujo|Jose Maria Gimenez|Sebastian Caceres|Mathias Olivera|Guillermo Varela|Nahitan Nandez|Federico Valverde|Giorgian De Arrascaeta|Rodrigo Bentancur|Manuel Ugarte|Nicolas de la Cruz|Maxi Araujo|Darwin Nunez|Federico Vinas|Rodrigo Aguirre|Facundo Pellistri"
"FRA|France|Mike Maignan|Theo Hernandez|William Saliba|Jules Kounde|Ibrahima Konate|Dayot Upamecano|Lucas Digne|Aurelien Tchouameni|Eduardo Camavinga|Manu Kone|Adrien Rabiot|Michael Olise|Ousmane Dembele|Bradley Barcola|Desire Doue|Kingsley Coman|Hugo Ekitike|Kylian Mbappe"
"SEN|Senegal|Edouard Mendy|Yehvann Diouf|Moussa Niakhate|Abdoulaye Seck|Ismail Jakobs|El Hadji Malick Diouf|Kalidou Koulibaly|Idrissa Gana Gueye|Pape Matar Sarr|Pape Gueye|Habib Diarra|Lamine Camara|Sadio Mane|Ismaila Sarr|Boulaye Dia|Iliman Ndiaye|Nicolas Jackson|Krepin Diatta"
"IRQ|Iraq|Jalal Hassan|Rebin Sulaka|Hussein Ali|Akam Hashem|Merchas Doski|Zaid Tahseen|Manaf Younis|Zidane Iqbal|Amir Al-Ammari|Ibrahim Bavesh|Ali Jasim|Youssef Amyn|Aimar Sher|Marko Farji|Osama Rashid|Ali Al-Hamadi|Aymen Hussein|Mohanad Ali"
"NOR|Norway|Orjan Nyland|Julian Ryerson|Leo Ostigard|Kristoffer Vassbakk Ajer|Marcus Holmgren Pedersen|David Moller Wolfe|Torbjorn Heggem|Morten Thorsby|Martin Odegaard|Sander Berge|Andreas Schjelderup|Patrick Berg|Erling Haaland|Alexander Sorloth|Aron Donnum|Jorgen Strand Larsen|Antonio Nusa|Oscar Bobb"
"ARG|Argentina|Emiliano Martinez|Nahuel Molina|Cristian Romero|Nicolas Otamendi|Nicolas Tagliafico|Leonardo Balerdi|Enzo Fernandez|Alexis Mac Allister|Rodrigo De Paul|Exequiel Palacios|Leandro Paredes|Nico Paz|Franco Mastantuono|Nico Gonzalez|Lionel Messi|Lautaro Martinez|Julian Alvarez|Giuliano Simeone"
"ALG|Algeria|Alexis Guendouz|Ramy Bensebaini|Youcef Atal|Rayan Ait-Nouri|Mohamed Amine Tougai|Aissa Mandi|Ismael Bennacer|Houssem Aquar|Hicham Boudaoui|Ramiz Zerrouki|Nabil Bentalab|Fares Chaibi|Riyad Mahrez|Said Benrahma|Anis Hadj Moussa|Amine Gouiri|Baghdad Bounedjah|Mohammed Amoura"
"AUT|Austria|Alexander Schlager|Patrick Pentz|David Alaba|Kevin Danso|Philipp Lienhart|Stefan Posch|Phillipp Mwene|Alexander Prass|Xaver Schlager|Marcel Sabitzer|Konrad Laimer|Florian Grillitsch|Nicolas Seiwald|Romano Schmid|Patrick Wimmer|Christoph Baumgartner|Michael Gregoritsch|Marko Arnautovic"
"JOR|Jordan|Yazeed Abulaila|Ihsan Haddad|Mohammad Abu Hashish|Yazan Al-Arab|Abdallah Nasib|Saleem Obaid|Mohammad Abualnadi|Ibrahim Saadeh|Nizar Al-Rashdan|Noor Al-Rawabdeh|Mohannad Abu Taha|Amer Jamous|Musa Al-Taamari|Yazan Al-Naimat|Mahmoud Al-Mardi|Ali Olwan|Mohammad Abu Zrayq|Ibrahim Sabra"
"POR|Portugal|Diogo Costa|Jose Sa|Ruben Dias|Joao Cancelo|Diogo Dalot|Nuno Mendes|Goncalo Inacio|Bernardo Silva|Bruno Fernandes|Ruben Neves|Vitinha|Joao Neves|Cristiano Ronaldo|Francisco Trincao|Joao Felix|Goncalo Ramos|Pedro Neto|Rafael Leao"
"COD|Congo DR|Lionel Mpasi|Aaron Wan-Bissaka|Axel Tuanzebe|Arthur Masuaku|Chancel Mbemba|Joris Kayembe|Charles Pickel|Ngalayel Mukau|Edo Kayembe|Samuel Moutoussamy|Noah Sadiki|Theo Bongonda|Meschak Elia|Yoane Wissa|Brian Cipenga|Fiston Mayele|Cedric Bakambu|Nathanael Mbuku"
"UZB|Uzbekistan|Utkir Yusupov|Farrukh Savfiev|Sherzod Nasrullaev|Umar Eshmurodov|Husniddin Aliqulov|Rustamjon Ashurmatov|Khojiakbar Alijonov|Abdukodir Khusanov|Odiljon Hamrobekov|Otabek Shukurov|Jamshid Iskanderov|Azizbek Turgunboev|Khojimat Erkinov|Eldor Shomurodov|Oston Urunov|Jaloliddin Masharipov|Igor Sergeev|Abbosbek Fayzullaev"
"COL|Colombia|Camilo Vargas|David Ospina|Davinson Sanchez|Yerry Mina|Daniel Munoz|Johan Mojica|Jhon Lucumi|Santiago Arias|Jefferson Lerma|Kevin Castano|Richard Rios|James Rodriguez|Juan Fernando Quintero|Jorge Carrascal|Jon Arias|Jhon Cordova|Luis Suarez|Luis Diaz"
"ENG|England|Jordan Pickford|John Stones|Marc Guehi|Ezri Konsa|Trent Alexander-Arnold|Reece James|Dan Burn|Jordan Henderson|Declan Rice|Jude Bellingham|Cole Palmer|Morgan Rogers|Anthony Gordon|Phil Foden|Bukayo Saka|Harry Kane|Marcus Rashford|Ollie Watkins"
"CRO|Croatia|Dominik Livakovic|Duje Caleta-Car|Josko Gvardiol|Josip Stanisic|Luka Vuskovic|Josip Sutalo|Kristijan Jakic|Luka Modric|Mateo Kovacic|Martin Baturina|Lovro Majer|Mario Pasalic|Petar Sucic|Ivan Perisic|Marco Pasalic|Ante Budimir|Andrej Kramaric|Franjo Ivanovic"
"GHA|Ghana|Lawrence Ati Zigi|Tariq Lamptey|Mohammed Salisu|Alidu Seidu|Alexander Djiku|Gideon Mensah|Caleb Yirenkyi|Abdul Issahaku Fatawu|Thomas Partey|Salis Abdul Samed|Kamaldeen Sulemana|Mohammed Kudus|Inaki Williams|Jordan Ayew|Andrew Ayew|Joseph Paintsil|Osman Bukari|Antoine Semenyo"
"PAN|Panama|Orlando Mosquera|Luis Mejia|Fidel Escobar|Andres Andrade|Michael Amir Murillo|Eric Davis|Jose Cordoba|Cesar Blackman|Cristian Martinez|Anibal Godoy|Adalberto Carrasquilla|Edgar Barcenas|Carlos Harvey|Ismael Diaz|Jose Fajardo|Cecilio Waterman|Jose Luiz Rodriguez|Alberto Quintero"
)

# Generate countries
$catId = 2
$pageNum = 2
foreach ($line in $countryData) {
    $parts = $line -split '\|'
    $prefix = $parts[0]
    $cname = $parts[1]
    $players = $parts[2..19]

    $categories += @{id=$catId; name=$cname; badgeAssetId=0}
    $pages += @{page=$pageNum; categoryId=$catId; layout="panini_a"}
    $pages += @{page=($pageNum+1); categoryId=$catId; layout="panini_b"}

    # 20 stickers per country
    for ($i = 1; $i -le 20; $i++) {
        $pg = if ($i -le 10) { $pageNum } else { $pageNum + 1 }
        if ($i -eq 1) { $nm = "Team Logo" }
        elseif ($i -eq 13) { $nm = "Team Photo" }
        else {
            # players array: index 0=p2, 1=p3, ..., 10=p12, 11=p14, ..., 17=p20
            $pidx = if ($i -le 12) { $i - 2 } else { $i - 3 }
            $nm = $players[$pidx]
        }
        $stickers += @{id="$prefix$i"; name=$nm; page=$pg; categoryId=$catId}
    }
    $catId++
    $pageNum += 2
}

# Build JSON manually for proper formatting
$sb = [System.Text.StringBuilder]::new()
[void]$sb.AppendLine('{')

# Categories
[void]$sb.AppendLine('  "categories": [')
for ($i = 0; $i -lt $categories.Count; $i++) {
    $c = $categories[$i]
    $comma = if ($i -lt $categories.Count - 1) { ',' } else { '' }
    $n = $c.name -replace '"','\"'
    [void]$sb.AppendLine("    {`"id`": $($c.id), `"name`": `"$n`", `"badgeAssetId`": $($c.badgeAssetId)}$comma")
}
[void]$sb.AppendLine('  ],')

# Pages
[void]$sb.AppendLine('  "pages": [')
for ($i = 0; $i -lt $pages.Count; $i++) {
    $p = $pages[$i]
    $comma = if ($i -lt $pages.Count - 1) { ',' } else { '' }
    [void]$sb.AppendLine("    {`"page`": $($p.page), `"categoryId`": $($p.categoryId), `"layout`": `"$($p.layout)`"}$comma")
}
[void]$sb.AppendLine('  ],')

# Stickers
[void]$sb.AppendLine('  "stickers": [')
for ($i = 0; $i -lt $stickers.Count; $i++) {
    $s = $stickers[$i]
    $comma = if ($i -lt $stickers.Count - 1) { ',' } else { '' }
    $n = $s.name -replace '"','\"'
    [void]$sb.AppendLine("    {`"id`": `"$($s.id)`", `"name`": `"$n`", `"page`": $($s.page), `"categoryId`": $($s.categoryId)}$comma")
}
[void]$sb.AppendLine('  ]')
[void]$sb.AppendLine('}')

$sb.ToString() | Out-File -FilePath "..\lib\data\albums\paniniwc2026.json" -Encoding UTF8 -NoNewline
Write-Host "Generated paniniwc2026.json with $($categories.Count) categories, $($pages.Count) pages, $($stickers.Count) stickers"
