Diaconescu Oana, 323 CD

Expresia este evaluata in 3 etape:

1.STOCAREA VALORILOR DIN ARBORE
Pornind de la adresa [root], se parcurge arborele in preordine si se retin
valorile din campul "data" intr-un vector de structuri care contin 2 campuri:
   - STRING (4 octeti): salveaza prima data adresa de inceput a stringului,
     preluata din arbore
   - TYPE (1 octet): poate avea valorile
            * 1 = structura curenta este un operand
            * 0 = structura curenta este un operator
            * -1 = structura curenta este un operand care a fost deja prelucrat
            si trebuie ignorat in prelucrari viitoare

2.CONVERSIA VALORILOR
Odata stocate adresele din arbore, se parcurge vectorul si se inlocuieste
fiecare adresa cu valoarea sa:
    -in cazul OPERANZILOR, se parcurge string-ul caracter cu caracter, se
    convertesc caracterele in cifre si se construieste un numar pe 4 bytes
    - in cazul OPERATORILOR, se adauga in primul byte codul ASCII al operatorului
    urmat de 3 octeti nuli
La acest pas, se stabilesc si tipurile celor 2 structuri.

3.EFECTUAREA OPERATIILOR
In acest moment, avem un array ce poate fi tratat ca o insiruire de operatori
si operanzi. Pentru a respecta ordinea operatiilor prefixate, se parcurge array-ul
pana cand se gaseste o secventa de tipul operator-operand1-operand2.
La fiecare iteratie, se executa doar aceste secvente, de la stanga la dreapta,
cu urmatoarele mentiuni:
  - odata efectuata o operatie, operanzii se marcheaza ca fiind folositi (byte-ul
  corespunzator tipului se schimba in -1)
  - la efectuarea unei operatii, rezultatul se pune in structura de tip operator,
  iar tipul structurii se schimba in '1' (devine operand)
  - in parcurgerea vectorului, orice strucura marcata cu '-1' este ignorata, astfel
  ca operanzii si operatorul unei operatii nu au neaparat pozitii consecutive
  in array (motiv pentru care pozitiile lor se salveaza pe stiva)
  
Prelucrarile se termina in momentul in care toate structurile au fost marcate
cu -1, mai putin una. In ultima structura ramasa se va regasi rezultatul.
