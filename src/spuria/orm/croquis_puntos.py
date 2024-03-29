# -*- coding: utf-8 -*-

from comunes import Base, DBSession
from rastreable import EsRastreable
from sqlalchemy import *
from sqlalchemy.ext.associationproxy import association_proxy
from sqlalchemy.ext.declarative import declared_attr
from sqlalchemy.orm import relationship, backref

class DibujableAsociacion(Base):
    __tablename__ = 'dibujable_asociacion'

    # Columnas
    dibujable_asociacion_id = Column(
        Integer, primary_key=True, autoincrement=True
    )
    discriminante = Column(String(45))

    # Propiedades
    @property
    def padre(self):
        return getattr(self, "{}_padre".format(self.discriminante))

    # Funciones
    @classmethod
    def creador(cls, discriminante):
        return lambda dibujable:DibujableAsociacion(
            dibujable=dibujable, discriminante=discriminante
        )

class Dibujable(Base):
    __tablename__ = 'dibujable'

    # Columnas
    dibujable_id = Column(Integer, primary_key=True, autoincrement=True)
    asociacion_id = Column(
        Integer, ForeignKey('dibujable_asociacion.dibujable_asociacion_id')
    )

    # Propiedades
    asociacion = relationship(
        'DibujableAsociacion', backref=backref('dibujable', uselist=False)
    )
    padre = association_proxy('asociacion', 'padre')

class EsDibujable(object):
    @declared_attr
    def dibujable_asociacion_id(cls):
        return Column(
            Integer, 
            ForeignKey("dibujable_asociacion.dibujable_asociacion_id")
        )

    @declared_attr
    def dibujable_asociacion(cls):
        discriminante = cls.__tablename__
        cls.dibujable = association_proxy(
            'dibujable_asociacion', 'dibujable', 
            creator=DibujableAsociacion.creador(discriminante)
        )
        return relationship(
            'DibujableAsociacion', backref=backref(
                "{}_padre".format(discriminante), uselist=False
            )
        )
    
    def __init__(self, *args, **kwargs):
        super(EsDibujable, self).__init__(*args, **kwargs)
        self.dibujable = Dibujable()

class Croquis(EsRastreable, Base):
    __tablename__ = 'croquis'

    # Columnas
    croquis_id = Column(Integer, primary_key=True, autoincrement=True)
    dibujable_id = Column(
        Integer, ForeignKey('dibujable.dibujable_id'), nullable=False
    )
    area = Column(Float)
    perimetro = Column(Float)
    
    # Propiedades
    dibujable = relationship('Dibujable', backref='croquis')
    puntos = relationship(
        "Punto", secondary=lambda:PuntoDeCroquis.__table__, 
        backref="croquis"
    )

    def __init__(self, *args, **kwargs):
        super(Croquis, self).__init__(*args, **kwargs)
        self.area = -1
        self.perimetro = -1

class Punto(Base):
    __tablename__ = 'punto'
    
    # Columnas
    punto_id = Column(Integer, primary_key=True, autoincrement=True)
    latitud = Column(Numeric(9,6))
    longitud = Column(Numeric(9,6))

    def __init__(self, latitud=None, longitud=None):
        self.latitud = latitud
        self.longitud = longitud

class PuntoDeCroquis(Base):
    __tablename__ = 'punto_de_croquis'

    # Columnas
    croquis_id = Column(
        Integer, ForeignKey('croquis.croquis_id'), 
        primary_key=True, autoincrement=False
    )
    punto_id = Column(
        Integer, ForeignKey('punto.punto_id'), 
        primary_key=True, autoincrement=False
    )

    # Propiedades
    croquis = relationship('Croquis')
    punto = relationship('Punto')

    def __init__(self, croquis=None, punto=None):
        self.croquis = croquis
        self.punto = punto
