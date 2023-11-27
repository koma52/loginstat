# 4. Bejelentkezési statisztika
Argumentumban adott felhasználó bejelentkezéseiről ad információt. Legutolsó bejelentkezése, mikor, honnan történt, összesen mennyi időt töltött bent, bejelentkezésenként átlagosan mennyi időt töltött bent, naponta átlag hányszor jelentkezik be, és naponta átlagosan mennyi időt tölt el azon a gépen. Írja ki azt a 10 gépet, ahonnan a legtöbb bejelentkezése történt. Ha dátumot adunk meg argumentumnak, akkor kiírja, hogy abban az időpontban kik voltak bejelentkezve (loginnév + teljes név formában).

### Pl1.:

```
$>bejelent user1
$>Utolso bejelentkezés: Mar 05 15:45 - 15:49
gépnév: nec21.iit.uni-miskolc.hu

...
```

### Pl2.:

```
$>bejelent 03:05:15:46

Marcius 5.-én 15 óra 46 perckor bent tartózkodott:

user1	Kis Miska
user2	Nagy Góliát

...
```

