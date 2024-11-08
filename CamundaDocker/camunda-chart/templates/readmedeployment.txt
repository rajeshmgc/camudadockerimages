Add this for Hasicorp vault integration

env:
  - name: VAULT_URL
    value: "{{ .Values.vault.url }}"
  - name: VAULT_ROLE_ID
    value: "{{ .Values.vault.roleId }}"
  - name: VAULT_SECRET_ID
    value: "{{ .Values.vault.secretId }}"
  - name: VAULT_DB_PATH
    value: "{{ .Values.vault.dbPath }}"
  - name: VAULT_LDAP_PATH
    value: "{{ .Values.vault.ldapPath }}"
