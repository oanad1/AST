%include "io.inc"

extern getAST
extern freeAST

section .data 
    contor_push db 0                ;Contorizeaza operatiile push
    contor_pop db 0                 ;Contorizeaza operatiile pop
    contor dd 0                     ;Index utilizat in functia atoi 
    negative_check db 0             ; 1 = numarul e negativ / 0 = numarul e pozitiv
    number dd 0                     ;Conversia unui string intr-un numar
    
    
    ;Variabile utilizate pentru a parcurge operatiile 
    elementArray times 3000 db 0    ;Vector cu elemente de tip element(cu campuri: string, tip)
    nr_elem dd 0                    ;Numarul de elemente din elementArray
    canceled dd 0                   ;Numarul de operanzi ce au fost folositi deja in operatii
    string_start dd 0
    
    
    ;Variabile utilizate pentru efectuarea unei operatii                
    opr dd 0                        ;Operatorul 
    nr1 dd 0                        ;Primul operand
    nr2 dd 0                        ;Al doilea operand 
    
section .bss
    ; La aceasta adresa, scheletul stocheaza radacina arborelui
    root: resd 1
    struc element
    .string:    resd 1    ; Initial adresa unui string, inlocuita cu valoarea sa pe 4 octeti(int sau char) 
    .type:      resb 1    ; Tipul stringului: 0 = operator, 1 = operand, -1 = operand "taiat" (deja folosit)
    endstruc
  

section .text
global main
main:
    mov ebp, esp
    push ebp
    mov ebp, esp
    
    ; Se citeste arborele si se scrie la adresa indicata mai sus
    call getAST
    mov [root], eax
    
  
    mov edx, [root]
    xor ebx, ebx
    xor ecx, ecx
    
    push edx
    inc byte[contor_push]
    jmp null_node
     
    ;Adauga adresa unui string in array 
add_string: 
    xor eax, eax
    mov eax, dword[nr_elem]
    mov dword[elementArray + eax * 5], ebx
    inc eax
    mov dword[nr_elem], eax
    jmp right
    
    ;Verifica daca se ajunge la un nod null  
null_node:
    cmp edx, 0 
    jmp end
    
pop_node: 
    pop edx               ;Se scoate un nou nod de pe stiva
    mov ebx, [edx]       
    inc byte[contor_pop]
    jmp add_string        ;Datele nodului se adauga in array

right:
    mov eax, edx
    add eax, 8            ;Se merge la nodul din dreapta 
    mov ebx, [eax] 
    cmp ebx, 0            ;Se verifica daca nodul e null 
    je left
    push ebx              ;Daca nu e null, este pus pe stiva 
    inc byte[contor_push]

left: 
    mov eax, edx
    add eax, 4           ;Se merge la nodul din stanga
    mov ebx, [eax]
    cmp ebx, 0           ;Se verifica daca nodul e null
    je null_node
    push ebx             ;Daca nu e null, este pus pe stiva 
    inc byte[contor_push]
    jmp null_node        ;Continua pana cand ajunge la un nod null 
    
    
end:
    xor eax, eax
    mov al, byte[contor_push]  
    cmp al, [contor_pop]  ;Se verifica daca toate nodurile au fost scoase de pe stiva
    jne pop_node          ;Daca au mai ramas noduri pe stiva, operatiile se repeta 

   

mov dword[contor], 0                  ;Retine pozitia curenta in array 

convert:
    mov dword[number], 0              ;Numarul (din stringul curent) este initializat cu 0
    mov byte[negative_check], 0       ;Numarul se presupune a fi pozitiv 
    mov ebx, [contor]
    mov eax, dword[elementArray + ebx*5]
    mov dword[string_start], eax      ;Se retine adresa unui element din array 
    xor ecx, ecx
 
atoi:
    xor ebx, ebx   
    mov eax, [string_start]
    mov bl, byte[eax +ecx]            ;Se preia primul byte din string 
    inc ecx 
    cmp bl, 0                         ;Se verifica daca s-a ajuns la finalul stringului
    je end_nr
    cmp bl, 45                        ;Se verifica daca byte-ul contine operatorul -
    je negative
    cmp bl, 42                        ;Se verifica daca byte-ul contine operatorul *
    je operator
    cmp bl, 43                        ;Se verifica daca byte-ul contine operatorul +
    je operator
    cmp bl, 47                        ;Se verifica daca byte-ul contine operatorul /
    je operator
   
    ;Daca ajunge aici, inseamna ca in stringul curent este un numar
    sub bl, 48                        ;Se transforma caracterul in cifra 
    mov eax, 10
    mul dword[number]
    mov dword[number], eax            ;Rezultatul anterior se inmulteste cu 10
    add dword[number], ebx            ;Cifra curenta se adauga rezultatului 
    jmp atoi
    
negative:
    mov eax, [string_start]            
    cmp byte[eax + ecx], 0            ;Verifica daca urmatorul byte dupa - este terminator de sir
    je operator                       ;In acest caz, '-' apare pe post de operator
    mov byte[negative_check], 1       ;In caz contrar, '-' apare ca parte a unui nr negativ 
    jmp atoi                          ;Se construieste numarul 
    
operator:
    mov eax, [contor]
    mov dword[elementArray + eax*5], 0      
    mov byte[elementArray + eax*5], bl       ;Se inlocuieste adresa din array cu valoarea operatorului
    mov byte[elementArray + eax*5 + 4], 0    ;Se marcheaza structura curenta ca fiind operator
    inc dword[contor]
    jmp end_atoi
    
end_nr:
    cmp byte[negative_check], 1
    jne operand
    mov eax, -1                             ;Daca numarul este precedat de '-', se inmulteste cu -1
    imul dword[number]
    mov dword[number], eax
    
operand:
    mov edx, dword[number]
    mov eax, [contor]
    mov dword[elementArray + eax*5], edx    ;Se inlocuieste adresa din array cu valoarea operandului
    mov byte[elementArray + eax*5 + 4], 1   ;Se marcheaza structura curenta ca fiind operand
    inc dword[contor]
    
end_atoi:
    mov eax, [contor]
    cmp dword[elementArray + eax*5], 0      ;Se verifica daca s-a ajuns la finalul array-ului
    jne convert                             
    
    
;Se traverseaza array-ul si se efectueaza orice secventa de tip operator-operand1-operand2  
;Array-ul se traverseaza repetat pana cand toti operanzii au fost folositi in operatii 
 
start_over:    
    xor ecx, ecx 
    mov dword[canceled], 0
    jmp op
  
next: 
    inc ecx                                 ;Se trece la urmatorul element din array 
    cmp dword[elementArray + ecx*5], 0      ;Se verifica daca este null 
    je number_or_end
    jmp op
  
number_or_end:
    cmp byte[elementArray + ecx*5 + 4], 1   ;Daca s-a gasit un 0 de tip operand se verifica mai departe
    je op 
    cmp byte[elementArray + ecx*5 + 4], -1  ;Daca s-a gasit un 0 de tip 'taiat' se trece peste 
    je next
    jmp is_it_over                          ;Daca se ajunge aici, 0 indica ca s-a terminat array-ul 
  
op:
    mov eax, [elementArray + ecx*5]         ;Se verifica un element din array 
    mov dword[opr], eax 
    cmp byte[elementArray + ecx*5 + 4], 1   ;Daca elementul curent e operand, se trece peste
    je next
    cmp byte[elementArray + ecx*5 + 4], -1  ;Daca elementul curent e operand 'taiat', se trece peste
    je  next  
    push ecx                                ;S-a gasit un operator si se salveaza pozitia sa pe stiva 
    
operand1:
    inc ecx 
    mov eax, [elementArray + ecx*5]         ;Se ia urmatoarea valoare din array 
    mov dword[nr1], eax      
    cmp byte[elementArray + ecx*5 + 4], -1  ;Se verifica daca valoarea a fost folosita/ 'taiata' 
    jne operand1_not_canceled
    jmp operand1                            ;Avanseaza in array cat timp gaseste operanzi 'taiati' 
  
operand1_not_canceled:                      ;Verifica daca a gasit un operand sau un operator 
    cmp byte[elementArray + ecx*5 + 4], 0  
    je go_back
    push ecx                                ;S-a gasit un operand si se salveaza pozitia sa pe stiva 
    
operand2: 
    inc ecx
    mov eax, [elementArray + ecx*5]         ;Se ia urmatoarea valoare din array
    mov dword[nr2], eax
    cmp byte[elementArray + ecx*5 + 4], -1  ;Se verifica daca valoarea a fost folosita/ 'taiata' 
    jne operand2_not_canceled
    jmp operand2                            ;Avanseaza in array cat timp gaseste operanzi 'taiati'
  
operand2_not_canceled:
    cmp byte[elementArray + ecx*5 + 4], 0
    je go2_back
    jmp determine_op                        ;Daca ajunge aici,se poate efectua operatia 
   
go_back:
    pop ecx                                 ;Se intoarce la pozitia initiala 
    jmp next
  
go2_back:                            
    pop ecx                                 ;Se intoarce la pozitia initiala
    pop ecx
    jmp next

;In functie de codul ASCII al operatorului se determina operatia de efectuat 
determine_op: 
    cmp byte[opr], 43
    je plus  
    cmp byte[opr], 45
    je minus  
    cmp byte[opr], 42
    je multiply  
    cmp byte[opr], 47 
    je divide 
    
;Efectuarea operatiilor - rezultatul se salveaza in eax 
plus:
    mov eax, dword[nr1]
    add eax, dword[nr2]
    jmp op_result
    
minus:
    mov eax, dword[nr1]
    sub eax, dword[nr2]
    jmp op_result
    
multiply:
    mov eax, dword[nr1]
    imul dword[nr2]
    jmp op_result
    
divide:
    xor edx, edx
    mov eax, dword[nr1]
    cdq
    idiv dword[nr2]
    jmp op_result

op_result: 
    mov edx, ecx
    mov byte[elementArray + ecx*5 + 4], -1   ;Al doilea operand se marcheaza ca fiind folosit
    pop ecx                                  ;Se scoate indicele primului operand de pe stiva 
    mov byte[elementArray + ecx*5 + 4], -1   ;Primul operand se marcheaza ca fiind folosit
    pop ecx 
    mov dword[elementArray + ecx*5], eax     ;In locul operatorului se pune rezultatul operatiei
    mov byte[elementArray + ecx*5 + 4], 1    ;Operatorul devine operand 
    mov ecx, edx                             ;Se continua prelucrarile de la pozitia ultimului operand  
    jmp next

;Verifica daca se mai pot face prelucrari 
is_it_over:
    mov dword[canceled], 0
    call count_canceled        
    mov ebx, [nr_elem]
    dec ebx 
    cmp ebx, [canceled]               ;Daca nr de elemente 'taiate' = (nr elem din vect - 1) => se termina         
    jne start_over
    
    xor ecx, ecx
    jmp get_result

;Numara cati operanzi 'taiati' exista in array
count_canceled:
    mov ecx, -1
    
is_canceled:
    inc ecx
    cmp byte[elementArray + ecx*5 + 4], -1
    jne check_end
    inc dword[canceled]
    
check_end:
    cmp ecx, dword[nr_elem]
    jne is_canceled
    ret
    
;Intoarce rezultatul - singurul operand netaiat din array 
get_result:
   cmp byte[elementArray + ecx*5 + 4], -1
   jne finally
   inc ecx 
   jmp get_result
   
   
finally:
   PRINT_DEC 4, [elementArray + ecx*5]
   
    ; Se elibereaza memoria alocata pentru arbore
    push dword [root]
    call freeAST
    mov esp, ebp
    xor eax, eax
    leave
    ret