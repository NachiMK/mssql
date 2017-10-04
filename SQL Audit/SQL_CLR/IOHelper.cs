using Microsoft.SqlServer.Server;
using System;
using System.Collections;
using System.Collections.Generic;
using System.Data.SqlTypes;
using System.IO;
using System.Linq;

namespace SQLCLR.DBATools.Library
{
    public partial class IOHelper
    {
        [SqlFunction]
        public static SqlString FileCopy(SqlString SourceFileName, SqlString DestFileName, SqlBoolean Overwrite)
        {
            try
            {
                // input parameters must not be NULL
                if (!SourceFileName.IsNull &&
                    !DestFileName.IsNull &&
                    !Overwrite.IsNull)
                {
                    // perform copy operation
                    File.Copy(SourceFileName.Value,DestFileName.Value,Overwrite.Value);
                    // return success message
                    return "Operation completed successfully.";
                }
                else
                {
                    // error if any input parameter is NULL
                    return "Error: NULL input parameter.";
                }
            }
            catch (Exception ex)
            {
                // return any unhandled error message
                return ex.Message;
            }
        }

        [SqlFunction (FillRowMethodName ="GetNextRow", TableDefinition ="KeyName NVARCHAR(MAX), KeyValue NVARCHAR(MAX)")]
        public static IEnumerable CopyMatchedFiles(SqlString DirectoryPath, SqlString SearchPattern
                                          , SqlString DestDirectoryPath, SqlBoolean Overwrite)
        {
            string strDesfile;
            string strDestPath;
            FileInfo fi;
            List<SqlReturnType> lstReturn = new List<SqlReturnType>();

            try
            {
                if (!DirectoryPath.IsNull &&
                    !SearchPattern.IsNull &&
                    !DestDirectoryPath.IsNull &&
                    !Overwrite.IsNull)
                {
                    // wildcard match found
                    var DirectoryOption = SearchOption.TopDirectoryOnly;
                    strDestPath = DestDirectoryPath.Value;
                    string[] fileList = Directory.GetFiles(DirectoryPath.Value, SearchPattern.Value, DirectoryOption);
                    lstReturn.Add(new SqlReturnType("No Of files Found", fileList.Length.ToString()));

                    foreach (string file in fileList)
                    {
                        fi = new FileInfo(file);
                        strDesfile = Path.Combine(strDestPath, fi.Name);
                        // perform delete operation
                        File.Copy(file, strDesfile, Overwrite.Value);
                        lstReturn.Add(new SqlReturnType(file, "Copied Successfully"));

                        if (File.Exists(strDesfile))
                            lstReturn.Add(new SqlReturnType(strDesfile, "Verified Successfully"));
                    }
                }
                else
                {
                    lstReturn.Add(new SqlReturnType("Error", "Some of Parameters are Null. Please pass in correct value."));
                }
            }
            catch (Exception ex)
            {
                // return any unhandled error message
                lstReturn.Add(new SqlReturnType("Error", ex.Message));
                if (ex.InnerException != null)
                    lstReturn.Add(new SqlReturnType("Inner Exception", ex.InnerException.Message));
            }

            return lstReturn;
        }

        public static void GetNextRow(object row, ref string KeyName, ref string KeyValue)
        {
            SqlReturnType st = (SqlReturnType)row;
            KeyName = st.KeyName;
            KeyValue = st.KeyValue;
        }


        [SqlFunction]
        public static SqlString FileDelete(SqlString Path)
        {
            try
            {
                // input parameter must not be NULL
                if (!Path.IsNull)
                {
                    // perform delete operation
                    File.Delete(Path.Value);

                    // return success message
                    return "Operation completed successfully.";
                }
                else
                {
                    // error if any input parameter is NULL
                    return "Error: NULL input parameter.";
                }
            }
            catch (Exception ex)
            {
                // return any unhandled error message
                return ex.Message;
            }
        }
        [SqlFunction]
        internal static SqlString FileDeleteMatch(SqlString DirectoryPath,
                                                    SqlString SearchPattern,
                                                    SqlBoolean Subdirectories,
                                                    SqlBoolean Match)
        {
            try
            {
                // input parameters must not be NULL
                if (!DirectoryPath.IsNull && !SearchPattern.IsNull && !Subdirectories.IsNull && !Match.IsNull)
                {
                    // if Subdirectories parameter is true, search subdirectories
                    var DirectoryOption = Subdirectories.Value == true ? SearchOption.AllDirectories : SearchOption.TopDirectoryOnly;
                    if (!Match.Value)
                    {
                        // wildcard match found
                        foreach (string FileFound in
                                        Directory.GetFiles(DirectoryPath.Value, SearchPattern.Value, DirectoryOption))
                        {
                            // perform delete operation
                            File.Delete(FileFound);
                        }
                    }
                    else
                    {
                        // wildcard match not found, use Except to get unmatched files
                        foreach (string FileFound in
                                        Directory.GetFiles(DirectoryPath.Value, "*", DirectoryOption).Except(
                                                    Directory.GetFiles(DirectoryPath.Value, SearchPattern.Value, DirectoryOption)))
                        {
                            // perform delete operation
                            File.Delete(FileFound);
                        }
                    }
                    // return success message
                    return "Operation completed successfully.";
                }
                else
                {
                    // error if any input parameter is NULL
                    return "Error: NULL input parameter.";
                }
            }
            catch (Exception ex)
            {
                // return any unhandled error message
                return ex.Message;
            }
        }

        [SqlFunction(FillRowMethodName = "GetNextRow", TableDefinition = "KeyName NVARCHAR(MAX), KeyValue NVARCHAR(MAX)")]
        public static IEnumerable MoveMatchedFiles(SqlString DirectoryPath
                                                 , SqlString SearchPattern
                                                 , SqlString DestDirectoryPath)
        {
            string strDesfile;
            string strDestPath;
            FileInfo fi;
            List<SqlReturnType> lstReturn = new List<SqlReturnType>();

            try
            {
                if (!DirectoryPath.IsNull &&
                    !SearchPattern.IsNull &&
                    !DestDirectoryPath.IsNull)
                {
                    // wildcard match found
                    var DirectoryOption = SearchOption.TopDirectoryOnly;
                    strDestPath = DestDirectoryPath.Value;
                    string[] fileList = Directory.GetFiles(DirectoryPath.Value, SearchPattern.Value, DirectoryOption);
                    lstReturn.Add(new SqlReturnType("# Of files Found", fileList.Length.ToString()));

                    foreach (string file in fileList)
                    {
                        fi = new FileInfo(file);
                        strDesfile = Path.Combine(strDestPath, fi.Name);

                        // perform delete operation
                        File.Move(file, strDesfile);
                        lstReturn.Add(new SqlReturnType(file, "Copied Successfully"));

                        if (File.Exists(strDesfile))
                            lstReturn.Add(new SqlReturnType(strDesfile, "Verified Successfully"));
                    }
                }
                else
                {
                    lstReturn.Add(new SqlReturnType("Error", "Some of Parameters are Null. Please pass in correct value."));
                }
            }
            catch (Exception ex)
            {
                // return any unhandled error message
                lstReturn.Add(new SqlReturnType("Error", ex.Message));
                if (ex.InnerException != null)
                    lstReturn.Add(new SqlReturnType("Inner Exception", ex.InnerException.Message));
            }

            return lstReturn;
        }

        [SqlFunction]
        public static SqlString FileMove(
                SqlString SourceFileName,
                SqlString DestFileName)
        {
            try
            {
                // input parameters must not be NULL
                if (!SourceFileName.IsNull &&
                    !DestFileName.IsNull)
                {
                    // perform move operation
                    File.Move(SourceFileName.Value,
                              DestFileName.Value);
                    // return success message
                    return "Operation completed successfully.";
                }
                else
                {
                    // error if any input parameter is NULL
                    return "Error: NULL input parameter.";
                }
            }
            catch (Exception ex)
            {
                // return any unhandled error message
                return ex.Message;
            }
        }
        [SqlFunction]
        public static SqlString FileReplace(
                SqlString SourceFileName,
                SqlString DestFileName,
                SqlString BackupFileName,
                SqlBoolean IgnoreMetadataErrors)
        {
            try
            {
                // input parameters must not be NULL
                if (!SourceFileName.IsNull &&
                    !DestFileName.IsNull &&
                    !BackupFileName.IsNull &&
                    !IgnoreMetadataErrors.IsNull)
                {
                    // perform replace operation
                    new FileInfo(SourceFileName.Value).Replace(DestFileName.Value,
                                                              BackupFileName.Value,
                                                              IgnoreMetadataErrors.Value);

                    // return success message
                    return "Operation completed successfully.";
                }
                else
                {
                    // error if any input parameter is NULL
                    return "Error: NULL input parameter.";
                }
            }
            catch (Exception ex)
            {
                // return any unhandled error message
                return ex.Message;
            }
        }
    };
}
