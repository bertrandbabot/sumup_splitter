# SumUp Ticket Splitter

Application Flutter tablette pour surveiller les transactions SumUp POS via `transactions/history`, lire `product_summary`, puis imprimer un ticket par article sur une imprimante Epson TM-m30III en réseau.

## Principe

L'application ne crée pas les commandes. Les commandes sont créées dans la caisse SumUp.

Toutes les X secondes, l'application appelle :

```http
GET https://api.sumup.com/v2.1/merchants/{MERCHANT_CODE}/transactions/history?limit=10&order=descending
Authorization: Bearer {API_KEY}
```

Elle filtre uniquement :

- `status == SUCCESSFUL`
- `type == PAYMENT`
- `payment_type == POS`

Puis elle lit :

```json
"product_summary": "Frites, 2 x Soda, Crêpe"
```

Et imprime :

- 1 ticket Frites
- 2 tickets Soda
- 1 ticket Crêpe

## Configuration

Dans l'application, ouvrir l'écran Réglages et renseigner :

- API Key SumUp
- Merchant Code SumUp
- IP imprimante, exemple `192.168.1.50`
- Port imprimante, généralement `9100`
- Intervalle de surveillance, exemple `5` secondes

## Important sécurité

La clé API est stockée localement dans `SharedPreferences`. Pour un usage professionnel long terme, il est préférable d'avoir un backend. Pour ton besoin événementiel/tablette autonome, ça fonctionne mais il faut protéger physiquement la tablette.

## Test HTTPie

```bash
http GET 'https://api.sumup.com/v2.1/merchants/TON_MERCHANT_CODE/transactions/history?limit=10&order=descending' \
Authorization:'Bearer TA_CLE_API'
```

## Lancement

```bash
flutter pub get
flutter run
```

## Structure

```text
lib/
  main.dart
  models/
  pages/
  services/
  widgets/
```
