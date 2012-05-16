﻿//-----------------------------------------------------------------------
// <copyright file="Api.svc.cs" company="Zuliaworks">
//     Copyright (c) Zuliaworks. All rights reserved.
// </copyright>
//-----------------------------------------------------------------------

namespace Zuliaworks.Netzuela.Spuria.Api
{
	using System;
    using System.Collections.Generic;
    using System.Configuration;                     // ConfigurationManager
    using System.Data;                              // DataTable
    using System.Linq;
    using System.Runtime.Serialization;
    using System.Security.Principal;                // IIdentity
    using System.ServiceModel;
    using System.ServiceModel.Web;
    using System.Text;
	
	using log4net;
	using Zuliaworks.Netzuela.Valeria.Logica;       // Conexion
	using Zuliaworks.Netzuela.Spuria.TiposApi;      // IApi
	
	using System.IO;
	
    /*
     * Para informacion sobre concurrencia ver: http://www.codeproject.com/KB/WCF/WCFConcurrency.aspx
     */

    /// <summary>
    /// Implementación de la API de Spuria.
    /// </summary>
    [ServiceBehavior(
        Namespace = Constantes.Namespace,
        ConcurrencyMode = System.ServiceModel.ConcurrencyMode.Multiple,
        InstanceContextMode = InstanceContextMode.PerSession)]
    public class Servidor : IApi
    {
        #region Variables y constantes

		private readonly int tiendaId;
		private readonly ILog log;
		public const string BaseDeDatos = "spuria";

        #endregion

        #region Constructores

        /// <summary>
        /// Inicializa una nueva instancia de la clase Servidor.
        /// </summary>
        public Servidor()
        {
			log = LogManager.GetLogger(typeof(Servidor));
			
			if (int.Parse(Cliente) == (int)Autentificacion.TipoDeUsuario.Anonimo)
			{
				log.Fatal("Imposible acceder con cuenta anonima");
				throw new Exception("Imposible acceder con cuenta anonima");
			}
			
			using (Conexion conexion = new Conexion(Sesion.CadenaDeConexion))
            {
				conexion.Conectar(Sesion.Credenciales[0], Sesion.Credenciales[1]);

                string sql = "SELECT tienda.tienda_id FROM tienda "
                			+ "JOIN cliente "
							+ "JOIN usuario "
							+ "WHERE usuario.usuario_id = " + this.Cliente + " LIMIT 1";
                DataTable t = conexion.Consultar(BaseDeDatos, sql);
                this.tiendaId = (int)t.Rows[0].ItemArray[0];
            }
        }

        #endregion

        #region Propiedades

        private string Cliente
        {
            //get { return OperationContext.Current.ServiceSecurityContext.AuthorizationContext.Properties["Usuario"].ToString(); }
			get { return Sesion.Propiedades["Usuario"].ToString(); }
        }

        #endregion

        #region Implementacion de interfaces

        /// <summary>
        /// Lista las bases de datos disponibles en el servidor.
        /// </summary>
        /// <returns>Nombres de las bases de datos encontradas.</returns>
        public string[] ListarBasesDeDatos()
        {
            List<string> resultadoFinal = new List<string>();

            try
            {
                using (Conexion conexion = new Conexion(Sesion.CadenaDeConexion))
                {
                    conexion.Conectar(Sesion.Credenciales[0], Sesion.Credenciales[1]);
                    string[] basesDeDatos = conexion.ListarBasesDeDatos();

                    var basesDeDatosAMostrar = (from bd in basesDeDatos
                                                where Permisos.EntidadesPermitidas.Keys.Any(k => string.Equals(k, bd, StringComparison.OrdinalIgnoreCase))
                                                select bd).ToList();

                    resultadoFinal = basesDeDatosAMostrar;
                }
            }
            catch (Exception ex)
            {
            	log.Fatal("Error de listado de base de datos");
                throw new Exception("Error de listado de base de datos", ex);
            }
			
            return resultadoFinal.ToArray();
        }

        /// <summary>
        /// Lista las tablas que pertenecen a la base de datos especificada.
        /// </summary>
        /// <param name="baseDeDatos">Nombre de la base de datos a consultar.</param>
        /// <returns>Nombres de las tablas encontradas.</returns>
        public string[] ListarTablas(string baseDeDatos)
        {
            List<string> resultadoFinal = new List<string>();

			try
            {
                using (Conexion conexion = new Conexion(Sesion.CadenaDeConexion))
                {
                    conexion.Conectar(Sesion.Credenciales[0], Sesion.Credenciales[1]);
                    string[] tablas = conexion.ListarTablas(baseDeDatos);

                    var tablasAMostrar = (from tabla in tablas
                                          where Permisos.EntidadesPermitidas[baseDeDatos].Any(t => string.Equals(t.Nombre, tabla, StringComparison.OrdinalIgnoreCase))
                                          select tabla).ToList();

                    resultadoFinal = tablasAMostrar;
                }
            }
            catch (Exception ex)
            {
				log.Fatal("Error de listado de base de tablas: baseDeDatos=" + baseDeDatos);
                throw new Exception("Error de listado de tablas", ex);
            }

            return resultadoFinal.ToArray();
        }

        /// <summary>
        /// Consulta la tabla de la base de datos indicada.
        /// </summary>
        /// <param name="baseDeDatos">Base de datos a consultar.</param>
        /// <param name="tabla">Nombre de la tabla a leer.</param>
        /// <returns>Tabla leída.</returns>
        public DataTableXml LeerTabla(string baseDeDatos, string tabla)
        {
            DataTableXml datosAEnviar = null;

            /*
             * Para convertir un LINQ en DataTable:
             * http://msdn.microsoft.com/en-us/library/bb386921.aspx
             * 
             * Para sacar un DataTable de un EF:
             * http://www.codeproject.com/Tips/171006/Convert-LINQ-to-Entity-Result-to-a-DataTable.aspx
             */

            if (!Permisos.EntidadesPermitidas.Keys.Contains(baseDeDatos))
            {
				log.Fatal("Argumento incorrecto: baseDeDatos=" + baseDeDatos);
                throw new ArgumentOutOfRangeException("baseDeDatos");
            }
			
            if (!Permisos.EntidadesPermitidas[baseDeDatos].Any(e => string.Equals(e.Nombre, tabla, StringComparison.OrdinalIgnoreCase)))
            {
				log.Fatal("Argumento incorrecto: tabla=" + tabla);
                throw new ArgumentOutOfRangeException("tabla");
            }

            try
            {
                using (Conexion conexion = new Conexion(Sesion.CadenaDeConexion))
                {
                    conexion.Conectar(Sesion.Credenciales[0], Sesion.Credenciales[1]);

                    string sql = "SELECT ";
                    Permisos.DescriptorDeTabla descriptor =
                        Permisos.EntidadesPermitidas[baseDeDatos].First(e => string.Equals(e.Nombre, tabla, StringComparison.OrdinalIgnoreCase));

                    for (int i = 0; i < descriptor.Columnas.Length; i++)
                    {
                        if (!string.Equals(descriptor.TiendaID, descriptor.Columnas[i], StringComparison.OrdinalIgnoreCase))
                        {
                            sql += descriptor.Columnas[i];

                            if ((i + 1) < descriptor.Columnas.Length)
                            {
                                sql += ", ";
                            }
                        }
                    }

                    sql += " FROM " + tabla + " WHERE " + descriptor.TiendaID + " = " + this.tiendaId.ToString();

                    DataTable t = conexion.Consultar(baseDeDatos, sql);
                    List<DataColumn> cp = new List<DataColumn>();
					
					/* 
					 * Seleccionamos todas las columnas que sean clave primaria y que no sean iguales a 
					 * descriptor.TiendaID (esta columna no va a ser enviada al cliente). Hay que hacer 
					 * esto para que toda tabla enviada siempre tenga una clave primaria.
					 */
                    foreach (string columna in descriptor.ClavePrimaria)
                    {
                        if (!string.Equals(columna, descriptor.TiendaID, StringComparison.OrdinalIgnoreCase))
                        {
                            cp.Add(t.Columns[columna]);
                        }
                    }

                    t.PrimaryKey = cp.ToArray();
                    datosAEnviar = t.DataTableAXml(baseDeDatos, tabla);
	            }
            }
            catch (Exception ex)
            {
				log.Fatal("Error de lectura");
                throw new Exception("Error de lectura", ex);
            }

            return datosAEnviar;
        }

        /// <summary>
        /// Escribe el contenido de la tabla en la base de datos.
        /// </summary>
        /// <param name="tablaXml">Tabla a escribir.</param>
        /// <returns>Indica si la operación de escritura tuvo éxito.</returns>
        public bool EscribirTabla(DataTableXml tablaXml)
        {
            if (!Permisos.EntidadesPermitidas.Keys.Contains(tablaXml.BaseDeDatos))
            {
				log.Fatal("Argumento incorrecto: tablaXml.BaseDeDatos=" + tablaXml.BaseDeDatos);
                throw new ArgumentOutOfRangeException("tablaXml");
            }

            if (!Permisos.EntidadesPermitidas[tablaXml.BaseDeDatos].Any(e => string.Equals(e.Nombre, tablaXml.NombreTabla, StringComparison.OrdinalIgnoreCase)))
            {
				log.Fatal("Argumento incorrecto: tablaXml.NombreTabla=" + tablaXml.NombreTabla);
                throw new ArgumentOutOfRangeException("tablaXml");
            }

            bool resultado = false;

            try
            {
                using (Conexion conexion = new Conexion(Sesion.CadenaDeConexion))
                {
                    conexion.Conectar(Sesion.Credenciales[0], Sesion.Credenciales[1]);

                    Permisos.DescriptorDeTabla descriptor =
                        Permisos.EntidadesPermitidas[tablaXml.BaseDeDatos].First(e => string.Equals(e.Nombre, tablaXml.NombreTabla, StringComparison.OrdinalIgnoreCase));
					
                    DataTable tablaRecibida = tablaXml.XmlADataTable();
					//tablaRecibida.WriteXml("/var/www/log/trXml.txt", XmlWriteMode.DiffGram);
					//tablaRecibida.WriteXmlSchema("/var/www/log/trEsquemaXml.txt");
					
					DataTable tablaProcesada = tablaRecibida.Copy();
					
					// Si la tabla original poseia una columna tienda_id, debemos colocarsela de nuevo
					if (descriptor.TiendaID != null)
					{
						List<DataRow> filasEliminadas = new List<DataRow>();
	                    DataColumn col = new DataColumn(descriptor.TiendaID, this.tiendaId.GetType());
	                    tablaProcesada.Columns.Add(col);
						
						for (int i = 0; i < tablaProcesada.Rows.Count; i++)
						{
							if (tablaProcesada.Rows[i].RowState == DataRowState.Deleted)
							{
								tablaProcesada.Rows[i].RejectChanges();
								tablaProcesada.Rows[i][col] = this.tiendaId;
								filasEliminadas.Add(tablaProcesada.Rows[i]);
								tablaProcesada.Rows[i].AcceptChanges();
							}
							else
							{
								tablaProcesada.Rows[i][col] = this.tiendaId;
							}
						}
						
						// Agregamos tienda_id al conjunto de claves primarias
						List<DataColumn> cp = new List<DataColumn>();
						
						foreach (string pk in descriptor.ClavePrimaria)
						{
							cp.Add(tablaProcesada.Columns[pk]);
						}
						
						tablaProcesada.PrimaryKey = cp.ToArray();
						filasEliminadas.ToList().ForEach(f => f.Delete());
					}
						
					// Reordenamos las columnas
                    for (int i = 0; i < descriptor.Columnas.Length; i++)
                    {
                        tablaProcesada.Columns[descriptor.Columnas[i]].SetOrdinal(i);
                    }
					
					//tablaProcesada.WriteXml("/var/www/log/tpXml.txt", XmlWriteMode.DiffGram);
					//tablaProcesada.WriteXmlSchema("/var/www/log/tpEsquemaXml.txt");
                    conexion.EscribirTabla(tablaXml.BaseDeDatos, tablaXml.NombreTabla, tablaProcesada);
                    resultado = true;
                }
            }
            catch (Exception ex)
            {
				log.Fatal("Error de escritura");
                throw new Exception("Error de escritura", ex);
            }

            return resultado;
        }

        #endregion
    }
}