using System;
using System.Collections.Generic;
using System.Text;

namespace SQLCLR.DBATools.Library
{
    public class SqlReturnType
    {
        private string _keyName;
        private string _keyValue;

        public string KeyName
        {
            get
            {
                return _keyName;
            }
            private set
            {
                _keyName = value;
            }
        }

        public string KeyValue
        {
            get
            {
                return _keyValue;
            }
            set
            {
                _keyValue = value;
            }
        }

        public SqlReturnType(string name)
        {
            this.KeyName = name;
            this.KeyValue = string.Empty;
        }

        public SqlReturnType(string name, string value)
        {
            this.KeyName = name;
            this.KeyValue = value;
        }

        public override string ToString()
        {
            return string.Format("Name:{0}, Value:{1}", this.KeyName, this.KeyValue);
        }

        public override bool Equals(object obj)
        {
            SqlReturnType s = (SqlReturnType)obj;
            return this.KeyName.Equals(s.KeyName);
        }

        public override int GetHashCode()
        {
            return _keyName.GetHashCode();
        }
    }
}
