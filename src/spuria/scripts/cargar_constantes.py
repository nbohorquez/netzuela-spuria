# -*- coding: utf-8 -*-

from constantes import (
    codigos_de_error,
    privilegios,
    idiomas,
    tipos_de_codigo,
    sexos,
    grados_de_instruccion,
    visibilidades,
    acciones,
    calificaciones,
    grupos_de_edades,
    estatus,
    dias,
    arbol_categorias
)
from spuria.comunes import ARCHIVO_CONFIG
from spuria.orm import (
    inicializar as inicializar_db, Base, DBSession, Estatus, Categoria, Accion,
    CodigoDeError, Idioma, TipoDeCodigo, Visibilidad, Dia, Administrador, 
    Privilegios, Calificacion, Sexo, GrupoDeEdad, GradoDeInstruccion
)
from spuria.search import inicializar as inicializar_se
import transaction

hash_cat = {}

def parsear_arbol_categorias(padre, arbol=arbol_categorias):
    padre_id = padre.categoria_id
    for nodo in arbol:
        hijo = Categoria(
            nombre=nodo['nombre'], hijo_de_categoria=padre_id
        )
        #padre.hijos.append(hijo)
        DBSession.add(hijo)
    
        if len(nodo['hijos']) > 0:
            parsear_arbol_categorias(hijo, nodo['hijos'])

        #hash_cat[tmp.categoria_id] = hijo

def main():
    inicializar_db(archivo=ARCHIVO_CONFIG)
    inicializar_se(archivo=ARCHIVO_CONFIG)

    with transaction.manager:
        print "Cargando constantes"
        DBSession.add_all(
            [CodigoDeError(error) for error in codigos_de_error]
            + [Privilegios(pri) for pri in privilegios]
            + [Idioma(idioma) for idioma in idiomas]
            + [TipoDeCodigo(tdc) for tdc in tipos_de_codigo]
            + [Sexo(sexo) for sexo in sexos]
            + [GradoDeInstruccion(valor=gdi[1], orden=gdi[0])
                for gdi in grados_de_instruccion]
            + [Visibilidad(vis) for vis in visibilidades]
            + [Accion(acc) for acc in acciones]
            + [Calificacion(cal) for cal in calificaciones]
            + [GrupoDeEdad(gde) for gde in grupos_de_edades]
            + [Estatus(est) for est in estatus]
            + [Dia(valor=dia[1], orden=dia[0]) for dia in dias]
        )
        
        print "Cargando categoria base"
        cat0 = Categoria(
            raiz=True, categoria_id='0.00.00.00.00.00', nombre='Inicio', 
            hijo_de_categoria='0.00.00.00.00.00', nivel=0
        )
        DBSession.add(cat0)
        print "Cargando categorias hijas"
        parsear_arbol_categorias(cat0)
        
        print "Creando administrador"
        adm = Administrador(
            creador=1, ubicacion=None, nombre='R2', apellido='D2',
            privilegios='Todos', correo_electronico='admin@netzuela.com',
            contrasena='$2a$12$MOM8uMGo9XmH1BDYPrTns.k/WLl6vt45qeKEXn5ZqoiBsQeBMfTQG'
        )
        DBSession.add(adm)

if __name__ == '__main__':
    main()
