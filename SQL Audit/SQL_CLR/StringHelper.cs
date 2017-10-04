using System.Collections;
using Microsoft.SqlServer.Server;

namespace SQLCLR.DBATools.Library
{
    public partial class StringHelper
    {
        [SqlFunction (FillRowMethodName ="GetNextToken", TableDefinition = "StringCol NVARCHAR(MAX)")]
        public static IEnumerable SplitStringCLR(string input, char separator)
        {
            string [] results;
            input = string.IsNullOrEmpty(input) ? string.Empty : input;
            results = input.Split(separator);
            return results;
        }

        public static void GetNextToken(object row, ref string theToken)
        {
            theToken = row.ToString();
        }
    }
}
