--SELECT 'SELECT ' + name + 'Cnt= COUNT(*) FROM ' + name + ' WITH (READUNCOMMITTED)' FROM sys.tables

SELECT CUSTOMERCnt= COUNT(*) FROM CUSTOMER WITH (READUNCOMMITTED)
SELECT DISTRICTCnt= COUNT(*) FROM DISTRICT WITH (READUNCOMMITTED)
SELECT HISTORYCnt= COUNT(*) FROM HISTORY WITH (READUNCOMMITTED)
SELECT ITEMCnt= COUNT(*) FROM ITEM WITH (READUNCOMMITTED)
SELECT NEW_ORDERCnt= COUNT(*) FROM NEW_ORDER WITH (READUNCOMMITTED)
SELECT ORDER_LINECnt= COUNT(*) FROM ORDER_LINE WITH (READUNCOMMITTED)
SELECT ORDERSCnt= COUNT(*) FROM ORDERS WITH (READUNCOMMITTED)
SELECT STOCKCnt= COUNT(*) FROM STOCK WITH (READUNCOMMITTED)
SELECT WAREHOUSECnt= COUNT(*) FROM WAREHOUSE WITH (READUNCOMMITTED)