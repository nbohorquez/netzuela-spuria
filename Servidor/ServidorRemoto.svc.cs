﻿using System;
using System.Collections.Generic;
using System.Linq;
using System.Runtime.Serialization;
using System.ServiceModel;
using System.ServiceModel.Web;
using System.Text;

using System.Configuration;                             // ConfigurationManager
using System.Data;                                      // DataSet
using System.IO;                                        // MemoryStream
using System.Security;                                  // SecureString
using Zuliaworks.Netzuela.Valeria.Comunes;              // ParametrosDeConexion
using Zuliaworks.Netzuela.Valeria.Logica;               // Conexion
using Zuliaworks.Netzuela.Valeria.Preferencias;         // ConexionesSection
using Zuliaworks.Netzuela.Spuria.Contrato;              // ISpuria

namespace Zuliaworks.Netzuela.Spuria.Servidor
{
    // Para informacion sobre concurrencia ver: http://www.codeproject.com/KB/WCF/WCFConcurrency.aspx

    [ServiceBehavior(ConcurrencyMode=ConcurrencyMode.Multiple, InstanceContextMode=InstanceContextMode.PerSession)]
    public class ServidorRemoto : ISpuria
    {
        #region Variables

        private ParametrosDeConexion _Parametros;
        private Conexion _Conexion;

        #endregion

        #region Constructores

        public ServidorRemoto()
        {
            _Parametros = CargarGuardar.CargarParametrosDeConexion("Local");

            if (_Parametros != null)
            {
                _Conexion = new Conexion(_Parametros);

                SecureString[] Credenciales = CargarGuardar.CargarCredenciales("Local");

                if (Credenciales.Length > 0)
                {
                    _Conexion.Conectar(Credenciales[0], Credenciales[1]);

                    Credenciales[0].Dispose();
                    Credenciales[0] = null;

                    Credenciales[1].Dispose();
                    Credenciales[1] = null;
                }
            }
        }

        #endregion

        #region Implementacion de interfaces

        public string[] ListarBasesDeDatos()
        {
            List<string> ResultadoFinal = new List<string>();

            try
            {
                string[] ResultadoBruto = _Conexion.ListarBasesDeDatos();

                foreach (string S in ResultadoBruto)
                    ResultadoFinal.Add(S);
            }
            catch (Exception ex)
            {
                throw new Exception("SPURIA: Error de listado de base de datos", ex);
            }

            return ResultadoFinal.ToArray();
        }

        public string[] ListarTablas(string BaseDeDatos)
        {
            List<string> ResultadoFinal = new List<string>();

            try
            {
                string[] ResultadoBruto = _Conexion.ListarTablas(BaseDeDatos);

                foreach (string S in ResultadoBruto)
                    ResultadoFinal.Add(S);
            }
            catch (Exception ex)
            {
                throw new Exception("SPURIA: Error de listado de tablas", ex);
            }

            return ResultadoFinal.ToArray();
        }

        public DataSetXML LeerTabla(string BaseDeDatos, string Tabla)
        {
            DataSetXML DatosAEnviar = null;

            try
            {
                DataTable T = _Conexion.LeerTabla(BaseDeDatos, Tabla);

                DataSet Set = new DataSet(Tabla);
                Set.Tables.Add(T);

                DatosAEnviar = new DataSetXML(Tabla, BaseDeDatos, Set.GetXmlSchema(), Set.GetXml());
            }
            catch (Exception ex)
            {
                throw new Exception("SPURIA: Error de lectura", ex);
            }

            return DatosAEnviar;
        }

        public bool EscribirTabla(DataSetXML TablaXML)
        {
            // Con codigo de: http://pstaev.blogspot.com/2008/04/passing-dataset-to-wcf-method.html

            DataSet TablaInterna = new DataSet();
            bool Resultado = false;

            try
            {
                TablaInterna.ReadXmlSchema(new MemoryStream(Encoding.Unicode.GetBytes(TablaXML.EsquemaXML)));
                TablaInterna.ReadXml(new MemoryStream(Encoding.Unicode.GetBytes(TablaXML.XML)));
                TablaInterna.WriteXml(TablaXML.NombreTabla + ".xml");
                TablaInterna.Tables[0].AcceptChanges();

                DataRowCollection Fila = TablaInterna.Tables[0].Rows;

                for (int i = 0; i < Fila.Count; i++)
                {
                    switch (TablaXML.EstadoFilas[i])
                    {
                        case DataRowState.Added:
                            Fila[i].SetAdded();
                            break;
                        case DataRowState.Deleted:
                            Fila[i].Delete();
                            break;
                        case DataRowState.Detached:
                            //Fila[i].Delete();
                            break;
                        case DataRowState.Modified:
                            Fila[i].SetModified();
                            break;
                        case DataRowState.Unchanged:
                            break;
                        default:
                            throw new Exception("No se reconoce el estado de la fila");
                    }
                }

                _Conexion.EscribirTabla(TablaXML.BaseDeDatos, TablaXML.NombreTabla, TablaInterna.Tables[0]);

                Resultado = true;
            }
            catch (Exception ex)
            {
                throw new Exception("SPURIA: Error de escritura", ex);
            }

            return Resultado;
        }

        #endregion
    }
}
