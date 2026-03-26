Kerberos main component:
- Key Distribution Center (KDC)
    - Database
    - Authentication Server (AS)
    - Ticket Granting Server (TGS)

Thu tu setup:
- Tao Princiapl DB:  kdb5_util create –r DATAPLATFORM.LOCAL –s
- Tao Admin principal sudo kadmin.local -q
- Start services:
    - /sbin/service kadmind start
    - /sbin/service krb5kdc star