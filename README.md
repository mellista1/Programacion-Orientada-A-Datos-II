# Programación Assembly x86 - Convención C
Arquitectura y Organización del Computador

**Entrega:** 12/09/2024

**Reentrega del TP1 completo (tp1-a, tp1-b y tp1-c):** 03/10/2024

-------------
En este taller vamos a trabajar con código `C` y `ASM` para ejercitar el uso y adhesión a contratos estructurales y comportamentales. El punto 1 se trata de un repaso de los conceptos vistos en clase, necesarios para encarar la programación en forma efectiva. El resto de los puntos se resuelven programando determinadas rutinas en assembly.

## Preparación: actualizando su fork del repositorio grupal
Es importante que, para este tp1-b y el próximo tp1-c, **no creen un nuevo fork de este repositorio** si no que actualicen el repositorio grupal que estaban utilizando para el tp1-a.
Estas son las instrucciones para sincronizar su fork grupal con el nuevo contenido de esta parte del TP1.
Cuando subamos el tp1-c, o si actualizamos algún archivo del tp1-a o tp1-b, deberán seguir estas mismas instrucciones para sincronizar su repositorio con el de la cátedra.

Para actualizar su fork con cambios del repositorio de la cátedra, que llamaremos "upstream", deben ejecutar los siguientes comandos desde la línea de comandos, estando ubicados dentro del clon local de su fork (de no recordar como clonar localmente su fork del repositorio grupal, revisitar las instrucciones del tp0):

1. Agregar el repositorio de la cátedra como *upstream* remoto:
   - Si usaron https:
	```sh
	git remote add upstream https://git.exactas.uba.ar/ayoc-doc/individual-<id_cuatrimestre>.git
	```
   - Si usaron ssh:
	```sh
	git remote add upstream git@git.exactas.uba.ar:ayoc-doc/individual-<id_cuatrimestre>.git
	```
2. Traer el último estado del upstream
```sh
git fetch upstream
```
3. Moverse al branch principal (`master`) si habían cambiado de branch, ya que los cambios se sincronizarán en dicho branch únicamente
```sh
git checkout master
```
4. Combinar los cambios locales con los del *upstream*
```sh
git merge upstream/master
```

Es posible que al ejecutar el merge les aparezca CONFLICT y diga que arreglen los conflictos para poder terminar el merge.
En ese caso, deben:
1. Resolver los conflictos, ya sea con la herramienta de resolución de conflictos de VScode o a mano (se recomienda utilizar VScode).
2. Una vez resueltos los conflictos, tomar nota de cuales archivos tenían conflictos que fueron resueltos y ejecutar:
```sh
git add <archivos modificados>
git commit -m "Merge con actualizaciones cátedra"
git push origin
```

## Ejercicio 0: Conceptos generales

En este punto introductorio deberán responder algunas preguntas conceptuales relacionadas a lo que vimos en las clases teóricas y en la presentación de hoy. Las preguntas tienen que ver con _convención de llamada y bibliotecas compartidas_.

- :pen_fountain: ¿Qué entienden por convencion de llamada? ¿Cómo está definida en la ABI de System V para 64 y 32 bits?
Por convención de llamada entendemos que existe un contrato por el cual se indica la forma de enviar o recibir variables/información.

En el caso de la ABI de System V para 64 bits
•Los registros RBX, RBP, R12, R13, R14 y R15 son no volatiles
•El valor de retorno ser´a almacenado en RAX para valores enteros1 y en XMM0 para flotantes
•Al salir de la funcion llamada la pila debe encontrarse en el mismo estado en el que estaba al ingresar
•Antes de realizar una llamada a una funcion, la pila debe estar alineada a 16 bytes
•Los parametros enteros se pasan de izquierda a derecha en RDI, RSI, RDX, RCX, R8, R9.
•Los parametros flotantes se pasan de izquierda a derecha en XMM0, XMM1, XMM2, XMM3, XMM4, XMM5, XMM6, XMM7.
•Si no hay registros disponibles se pasan  de derecha a izquierda a traves de la pila
•Las estructuras se tratan de forma especial 
•Si el valor a retornar es una estructura grande la funcion llamadora reserva espacio

En el caso de la ABI de System V para 32 bits
•Los registros EBX, EBP, ESI y EDI son no volatiles.
•El valor de retorno sera almacenado en EAX.
•Al salir de la funcion llamada la pila debe encontrarse en el mismo estado en el que estaba al ingresar.
•Los parametros se pasaran de derecha a izquierda a traves de la pila haciendo PUSH.
•Antes de realizar una llamada a una funcion la pila debe quedar alineada a 16 bytes.
•Si el valor a retornar es una estructura grande la funcion llamadora reserva espacio.



- :pen_fountain: ¿Quién toma la responsabilidad de asegurar que se cumple la convención de llamada en `C`? ¿Quién toma la responsabilidad de asegurar que se cumple la convención de llamada en `ASM`? 

El que se ocupa de cumplir la convencion de llamada en C es el compilador. En el caso de assembler es el usuario.

- :pen_fountain: ¿Qué es un stack frame? ¿A qué se le suele decir **prólogo y epílogo**?

El stack frame son los datos almacenados en el stack por una llamada de funcion.
El prologo y el epilogo son dos partes del codigo de una funcion.
En el prologo se reserva espacio de la pila para datos temporales y se agrega padding en caso de que quede la pila desalineada.
En el epilogo se restauran valores de registros no volatiles y devuelve la pila a su estado inicial. 
- :pen_fountain: ¿Cuál es el mecanismo utilizado para almacenar **variables temporales**?

Si queres almacenar variables temporales podes utilizar los registros (en caso de no volatiles tendrias que restaurar los valores al salir de la funcion). y en caso de que no tener suficientes registros podes utilizar la pila. 

- :pen_fountain: ¿A cuántos bytes es necesario alinear la pila si utilizamos funciones de `libc`? ¿Si la pila está alienada a 16 bytes al realizarse una llamada función, cuál va a ser su alineamiento al ejecutar la primera instrucción de la función llamada?

Para realizar llamadas de funciones de `libc` es necesario alinear la pila a 16 bytes.
En caso de realizar una llamada de una funcion, la pila va a quedar desalineada temporalmente por 8 bytes ya que se hace un push a la pila de la direcion de rsp.

- :pen_fountain: Una actualización de bibliotecas realiza los siguientes cambios a distintas funciones. ¿Cómo se ven impactados los programas ya compilados?
_Sugerencia:_ Describan la convención de llamada de cada una (en su versión antes y después del cambio).

	- Una biblioteca de procesamiento cambia la estructura `pixel_t`:
		* Antes era `struct { uint8_t r, g, b, a; }`
		* Ahora es `struct { uint8_t a, r, g, b; }`

		Los programas ya compiados va a tomar las variables:
			a como si fuera r
			r como si fuera g
			g como si fuera b
			b como si fuera a
		Esto, dependiendo de la funcion, va a devolver un resultado erroneo , es decir, es importante el orden en el que se pasan las variables a través de los registros. 
		
		

			¿Cómo afecta esto a la función `void a_escala_de_grises(uint32_t ancho, uint32_t alto, pixel_t* data)`?
			
			Esto va a hacer que la funcion a_escala_de_grises funciona de forma incorrecta ya que va a leer los datos en pixel_t*
			en el orden: a, r, g, b cuando fue almacenado en el orden r, g, b, a.


	- Se reordenan los parámetros (i.e. intercambian su posición) de la función `float sumar_floats(float* array, uint64_t tamano)`.

	Esto va a hacer que la funcion sumar_float tome la direccion de memoria hacia el primer float como tamaño y viceversa. Debido a eso la funcion va a funcionar mal.

	- La función `uint16_t registrar_usuario(char* nombre, char* contraseña)` registra un usuario y devuelve su ID. Para soportar más usuarios se cambia el tipo de retorno por `uint64_t`.
	
	Esto depende de como sea la implementacion de registrar_usuario.
	En caso de que tracke la ultima id utilizando la id guardada en memoria. Ejemplo
	Guardo en memoria: Nombre-Contraseña-ID-Puntero al proximo.
	Entonces vas a tener que actualizar el tamaño de todas las IDs.

	En caso de que no guardes en memoria la ID Ejemplo
	Guardo en memoria: Nombre-Contraseña-Puntero al proximo. (y seguramente tenga la ultima id guardada en alguna variable y, cuando intente de acceder algun usuario, utilice el offset calculado con la ID)
	En ese caso solamente tendria que actualizar la variable de ultima ID y el tamaño dentro del codigo de los offsets.

	En ambos casos deberan contemplar el caso donde utilice el retorno de registrar usuario para que soporte el int64.

	- La función `void cambiar_nombre(uint16_t user_id, char* nuevo_nombre)` también recibe la misma actualización. ¿Qué sucede ahora?

	Ahora que el user_id es de 64 bits ahora al cambiar el nombre acceda a otro usuario que no es	
	Para arreglar esto tendrias que cambiar el tamaño del parametro a uint_64_t y contemplar como impacta en los offsets para acceder a el lugar en memoria de ese usuario. 

	- Se reordenan los parámetros de `int32_t multiplicar(float a, int32_t b)`.

	En este caso, por convencion llamada, no habria cambios. PREGUNTAR :(

	
Una vez analizados los casos específicos describan la situación general:
- :pen_fountain: ¿Qué sucede si una función externa utilizada por nuestro programa _(Es decir, que vive en una **biblioteca compartida**)_ cambia su interfaz (parámetros o tipo devuelto) luego de una actualización?

Vas a tener que contemplar en nuevo tipo devuelto en caso de que ese sea el cambio.
En caso de que exista un cambio del orden de parametros entonces vas a tener que pasarselo en el orden correcto (PREGUNTAR X LO DE ARRIBA)
En caso de que se cambien el tipo de dato de los parametros entonces vas a tambien tener que contemplar ese cambio 

## Ejercicio 1: C/ASM pasaje de parámetros

En este punto y en los que siguen vamos a desarrollar funciones en `ASM` que son llamadas desde código `C` haciendo uso de la convención de llamada de 64 bits. Pueden encontrar el código vinculado a este checkpoint en [checkpoint2.asm](src/checkpoint2.asm) y [checkpoint2.c](src/checkpoint2.c), la declaración de las funciones se encuentra en [checkpoints.h](src/checkpoints.h). También ahí mismo se explica qué debe hacer dicha función.

Programen en assembly las siguientes funciones:

- `alternate_sum_4`
- `alternate_sum_4_using_c`
- `alternate_sum_4_simplified`
- `alternate_sum_8`
- `product_2_f`
- `product_9_f`

El archivo que tienen que editar es [checkpoint2.asm](src/checkpoint2.asm). Para todas las declaraciones de las funciones en `ASM` van a encontrar la firma de la función. Completar para cada parámetro en qué registro o posición de la pila se encuentra cada uno.

> *La siguiente información aplica para este ejercicio y los siguientes*

### Compilación y Testeo

El archivo [`main.c`](src/main.c) es para que ustedes realicen pruebas básicas de sus funciones. Siéntanse a gusto de manejarlo como crean conveniente.
Para compilar el código y poder correr las pruebas cortas implementadas en main deberá ejecutar `make main` y luego `./runMain.sh`.
En cambio, para compilar el código y correr las pruebas intensivas deberá ejecutar `./runTester.sh`.
El programa puede correrse con `./runMain.sh` para verificar que no se pierde memoria ni se realizan accesos incorrectos a la misma.

#### Pruebas intensivas (Testing)

Entregamos también una serie de *tests* o pruebas intensivas para que pueda verificarse el buen funcionamiento del código de manera automática. Para correr el testing se debe ejecutar `./runTester.sh`, que compilará el *tester* y correrá todos los tests de la cátedra.
Luego de cada test, el *script* comparará los archivos generados por su TP con las soluciones correctas provistas por la cátedra.
También será probada la correcta administración de la memoria dinámica.

## Ejercicio 2: Recorrido de estructuras C/ASM

En este checkpoint vamos implementar código vinculado al acceso de estructuras. En particular, vamos a usar dos estructuras muy similares a `lista\char_t` del TP1a y vamos a implementar en `ASM` la función que contaba la cantidad total de elementos de la lista, para ambas estructuras. Pueden encontrar el código vinculado a este checkpoint en [`checkpoint3.c`](src/checkpoint3.c) y [`checkpoint3.asm`](src/checkpoint3.asm).

Las definiciones de las estructuras las pueden encontrar en el archivo [`checkpoints.h`](src/checkpoints.h). Las de los nodos correspondientes son las siguientes:

```c
	typedef struct nodo_s {
		struct nodo_s* next;   // Siguiente elemento de la lista o NULL si es el final
		uint8_t categoria;     // Categoría del nodo
		uint32_t* arreglo;     // Arreglo de enteros
		uint32_t longitud;     // Longitud del arreglo
	} nodo_t;
	
	typedef struct __attribute__((__packed__)) packed_nodo_s {
		struct packed_nodo_s* next;   // Siguiente elemento de la lista o NULL si es el final
		uint8_t categoria;     // Categoría del nodo
		uint32_t* arreglo;     // Arreglo de enteros
		uint32_t longitud;     // Longitud del arreglo
	} packed_nodo_t;
```

Programen en assembly las funciones:

1. `uint32_t cantidad_total_de_elementos(lista_t* lista)`,
2. `uint32_t cantidad_total_de_elementos_packed(packed_lista_t* lista)`

El archivo que tienen que editar es [`checkpoint3.asm`](src/checkpoint3.asm). Para todas las declaraciones de las funciones en `ASM` van a encontrar la firma de la función. Completar para cada parámetro en qué registro o posición de la pila se encuentra cada uno.

## Ejercicio 3: Memoria dinámica con strings

En este checkpoint vamos implementar código vinculado para el manejo de strings. Recuerden que `C` representa a los strings como una sucesión de `char`'s terminada con el caracter nulo `'\0'`. Pueden encontrar el código vinculado a este checkpoint en [`checkpoint4.c`](src/checkpoint4.c) y [`checkpoint4.asm`](src/checkpoint4.asm). Recuerden que para realizar el clonado de un string, van a tener que usar memoria dinámica.
Luego analizaremos el uso de la pila.

Programen en assembly las siguientes funciones. El archivo que tienen que editar es [`checkpoint4.asm`](src/checkpoint4.asm).

1. `strLen`
2. `strPrint`
3. `strClone`
4. `strCmp`
5. `strdelete`
    
## Ejercicio 4: La pila...
### Preliminar
Para este ejercicio utilizarán el debugger `gdb` para indagar en un binario.
Se recomienda **fuertemente** instalar la extensión [gdb-dashboard](https://github.com/cyrus-and/gdb-dashboard) que nos generará una interfaz más informativa y fácil de entender al momento de debuggear.
La instalación consiste en descargar un archivo al `home` de la computadora, no requiere permisos especiales, por lo que pueden hacerlo incluso en las computadoras del laboratorio.

Pueden instalar `gdb dashboard` utilizando el siguiente comando:
```sh
wget -P ~ https://github.com/cyrus-and/gdb-dashboard/raw/master/.gdbinit
```
Además, para habilitar syntax highlighting, pueden opcionalmente instalar el paquete `pygments` de python con el siguiente comando:
```sh
pip install pygments
``` 

### Ejercicio
En una máquina de uno de los labos de la facultad, nos encontramos un _pendrive_ con un programa ejecutable de linux adentro.
Investigando un poco vimos que se trata de un programa de prueba interno de una importante compañía de software, que sirve para probar la validez de claves para su sistema operativo.
Si logramos descubrir la clave... bueno, sería interesante...
Para ello llamamos por teléfono a la división de desarrollo en USA, haciéndonos pasar por Susan, la amiga de John (quien averiguamos estuvo en la ECI dando una charla sobre seguridad).
De esa llamada averiguamos:

- El programador que compiló el programa olvidó sacar los símbolos de *debug* en la función que imprime el mensaje de autenticación exitosa/fallida.
  Esta función toma un único parámetro de tipo `int` llamado `miss` que utiliza para definir y imprimir un mensaje de éxito o de falla de autenticación.
- La clave está guardada en una variable local (de tipo `char*`) de alguna función en la cadena de llamados de la función de autenticación.

Se pide:

1. Correr el programa con `gdb` y poner un breakpoint en la función que imprime el mensaje de autenticación exitosa/fallida.
2. :pen_fountain: Imprimir una porción adecuada del stack, con un formato adecuado para ver si podemos encontrar la clave.
3. :pen_fountain: ¿En que función se encuentra la clave? Explicar el mecanismo de como se llega a encontrar la función en la que se calcula la clave.

en gdb use el comando info functions para ver que funciones tenia, y a base de eso puse los breakpoints para entrar a la funcion y ver que hacia, como modificaba registros y stack. Luego llegue a la conclusion que la funcion do more stuff contenia la comparacion de strings y como recibia dos parametros uno era la clave que ingrese y la otra la correcta

La clave encontrada fue: clave_192.168.0.76

### Ayuda de GDB:
- :exclamation: El comando `backtrace` de gdb permite ver el stack de llamados hasta el momento actual de la ejecución del programa, y el comando `frame` permite cambiar al frame determinado. 
  `info frame` permite ver información del frame activo actualmente.
- Los parámetros pasados al comando `run` dentro de gdb se pasan al binario como argumentos, por ejemplo `run clave` iniciará la ejecución del binario cargado en gdb, pasándole un argumento con valor "clave".
- El comando `p {tipo} dirección` permite pasar a `print` cómo se debe interpretar el contenido de la dirección.  
Por ejemplo: `p {char*} 0x12345678` es equivalente a `p *(char**) 0x12345678`.  
  - En el ejemplo mostrado, sabemos que en la dirección `0x12345678` hay un puntero a `char`, por lo que le decimos a `gdb` que interprete el contenido de esa dirección como un puntero a `char`.
- El comando `p ({tipo} dirección)@cantidad` permite imprimir una cantidad de elementos de un tipo determinado a partir de una dirección.
Esto es sumamente práctico cuando conocemos la dirección y el tipo de una variable y queremos ver su contenido.
