%  Aριθμοί μητρώου και ονοματεπώνυμα της ομάδας.
	Στραπάτσα Θεοδώρα 4066
	Καλογεράκη Δεσποίνη 4272

% ---------------------------------------
% Απενεργοποίηση προειδοποιήσεων για singleton variables
:- style_check(-singleton).

% Ρύθμιση υποστήριξης UTF-8 για ελληνικά
%:- set_prolog_flag(encoding, utf8).

% Φόρτωση αρχείων δεδομένων
:- consult('houses.pl').
:- consult('requests.pl').

% ---------------------------------------
% Κύρια συνάρτηση: Εμφανίζει το μενού και περιμένει επιλογή χρήστη
run :-
    repeat,
    nl,
    writeln('Μενού:'),
    writeln('======'),
    writeln('1 - Προτιμήσεις ενός πελάτη'),
    writeln('2 - Μαζικές προτιμήσεις πελατών'),
    writeln('3 - Επιλογή πελατών μέσω δημοπρασίας'),
    writeln('0 - Έξοδος'),
    write('Επιλογή: '),
    read(Choice),
    execute(Choice),
    Choice = 0, !.

% Εκτέλεση επιλογής χρήστη
execute(0) :- writeln('Έξοδος...').
execute(1) :- interactive_mode, !.
execute(2) :- batch_mode, !.
execute(3) :- auction_mode, !.
execute(_) :- writeln('Μη έγκυρη επιλογή.'), fail.

% ---------------------------------------
% ΔΙΑΔΡΑΣΤΙΚΗ λειτουργία: εισαγωγή προτιμήσεων από χρήστη
interactive_mode :-
    writeln('\nΔώσε τις παρακάτω πληροφορίες:'),
    write('Ελάχιστο Εμβαδόν: '), read(MinArea),
    write('Ελάχιστος αριθμός υπνοδωματίων: '), read(MinBedrooms),
    write('Να επιτρέπονται κατοικίδια; (yes/no): '), read(Pets),
    write('Από ποιον όροφο και πάνω να υπάρχει ανελκυστήρας; '), read(ElevatorLimit),
    write('Ποιο είναι το μέγιστο ενοίκιο που μπορείς να πληρώσεις; '), read(MaxTotal),
    write('Πόσα θα έδινες για ένα διαμέρισμα στο κέντρο της πόλης (στα ελάχιστα τετραγωνικά);'), read(MaxCenter),
    write('Πόσα θα έδινες για ένα διαμέρισμα στα προάστια της πόλης (στα ελάχιστα τετραγωνικά);'), read(MaxSuburb),
    write('Πόσα θα έδινες για κάθε τετραγωνικό διαμερίσματος πάνω από το ελάχιστο;'), read(ExtraM2),
    write('Πόσα θα έδινες για κάθε τετραγωνικό κήπου;'), read(ExtraGarden),
    
    % Δημιουργία δομής request για έλεγχο
    Request = request(_, MinArea, MinBedrooms, Pets, ElevatorLimit, MaxTotal, MaxCenter, MaxSuburb, ExtraM2, ExtraGarden),

    % Συλλογή όλων των σπιτιών
    findall(H, house(_, _, _, _, _, _, _, _, _), AllHouses),

    % Φιλτράρισμα σπιτιών που ικανοποιούν τις προτιμήσεις
    include(compatible(Request), AllHouses, CompatibleHouses),

    % Εμφάνιση κατάλληλων σπιτιών
    print_compatible_houses(CompatibleHouses),

    % Πρόταση καλύτερου σπιτιού
    recommend_house(CompatibleHouses).

% ---------------------------------------
% Κανόνας συμβατότητας μεταξύ request και house
compatible(request(_, MinArea, MinBedrooms, PetsReq, ElevatorLimit, _, _, _, _, _),
           house(_, Bedrooms, Area, Floor, Elevator, Pets, _, _, _)) :-
    Area >= MinArea,
    Bedrooms >= MinBedrooms,
    (PetsReq == yes -> Pets == yes ; true),
    (Floor >= ElevatorLimit -> Elevator == yes ; true).

% Εμφάνιση όλων των κατάλληλων σπιτιών
print_compatible_houses([]) :-
    writeln('Δεν υπάρχει κατάλληλο σπίτι!').
print_compatible_houses([house(Address, Bedrooms, Area, Floor, Elevator, Pets, Garden, Rent, Center)|T]) :-
    format('\nΚατάλληλο σπίτι στην διεύθυνση: ~w\n', [Address]),
    format('Υπνοδωμάτια: ~w\n', [Bedrooms]),
    format('Εμβαδόν: ~w\n', [Area]),
    format('Εμβαδόν κήπου: ~w\n', [Garden]),
    format('Είναι στο κέντρο της πόλης: ~w\n', [Center]),
    format('Επιτρέπονται κατοικίδια: ~w\n', [Pets]),
    format('Όροφος: ~w\n', [Floor]),
    format('Ανελκυστήρας: ~w\n', [Elevator]),
    format('Ενοίκιο: ~w\n', [Rent]),
    print_compatible_houses(T).

% Πρόταση καλύτερου σπιτιού από τη λίστα
recommend_house([]).
recommend_house(Houses) :-
    find_cheapest(Houses, Cheapest),
    find_biggest_garden(Cheapest, WithGarden),
    find_biggest_house(WithGarden, [house(Address,_,_,_,_,_,_,_,_)]),
    format('\nΠροτείνεται η ενοικίαση του διαμερίσματος στην διεύθυνση: ~w\n', [Address]).

% Βρίσκει τα φθηνότερα σπίτια
find_cheapest(Houses, Result) :-
    maplist(arg(8), Houses, Rents),
    min_list(Rents, MinRent),
    include({MinRent}/[_H]>>arg(8,_H,MinRent), Houses, Result).

% Βρίσκει τα σπίτια με τον μεγαλύτερο κήπο
find_biggest_garden(Houses, Result) :-
    maplist(arg(7), Houses, Gardens),
    max_list(Gardens, MaxGarden),
    include({MaxGarden}/[_H]>>arg(7,_H,MaxGarden), Houses, Result).

% Βρίσκει τα σπίτια με το μεγαλύτερο εμβαδόν
find_biggest_house(Houses, Result) :-
    maplist(arg(3), Houses, Areas),
    max_list(Areas, MaxArea),
    include({MaxArea}/[_H]>>arg(3,_H,MaxArea), Houses, Result).

% ---------------------------------------
% Κριτήρια για μαζική σύγκριση (batch & auction mode)
matches(House, Area, Bedrooms, Pets, ElevatorLimit, MaxTotal, MaxRent, MaxUtilities, MaxDistance, MinFloor) :-
    house(House, Floor, HArea, HasElevator, HBedrooms, PetsAllowed, _, Distance, Rent),
    HArea >= Area,
    HBedrooms >= Bedrooms,
    (Pets == yes -> PetsAllowed == yes ; true),
    (Floor >= ElevatorLimit -> HasElevator == yes ; true),
    Distance =< MaxDistance,
    Floor >= MinFloor,
    Utilities is Rent * 0.2, % Πρόχειρος υπολογισμός κοινόχρηστων
    Total is Rent + Utilities,
    Rent =< MaxRent,
    Utilities =< MaxUtilities,
    Total =< MaxTotal.

% ---------------------------------------
% Μαζική λειτουργία: έλεγχος όλων των requests
batch_mode :-
    forall(
        request(Name, Area, Bedrooms, Pets, ElevatorLimit, MaxTotal, MaxRent, MaxUtilities, MaxDistance, MinFloor),
        (
            format("\nΚατάλληλα διαμερίσματα για τον πελάτη: ~w:\n", [Name]),
            findall(House,
                matches(House, Area, Bedrooms, Pets, ElevatorLimit, MaxTotal, MaxRent, MaxUtilities, MaxDistance, MinFloor),
                Houses),
            (Houses \= []
            -> forall(member(H, Houses), format(" - ~w\n", [H]))
            ;  writeln("  Δεν βρέθηκε κατάλληλο σπίτι.")
            )
        )
    ),
writeln("=======================================").

% ---------------------------------------
% Δημοπρασία: κάθε σπίτι δίνεται στον πρώτο πελάτη που το θέλει
auction_mode :-
    findall(House, house(House,_,_,_,_,_,_,_,_), Houses),
    forall(
        request(Name, Area, Bedrooms, Pets, ElevatorLimit, MaxTotal, MaxRent, MaxUtilities, MaxDistance, MinFloor),
        (
            findall(HouseName,
                (
                    member(HouseName, Houses),
                    matches(HouseName, Area, Bedrooms, Pets, ElevatorLimit, MaxTotal, MaxRent, MaxUtilities, MaxDistance, MinFloor)
                ),
                Suitable),
            (Suitable \= []
            -> nth0(0, Suitable, BestHouse),
               format("O πελάτης ~w θα νοικιάσει το διαμέρισμα στην διεύθυνση: ~w\n", [Name, BestHouse])
            ;  format("O πελάτης ~w δεν θα νοικιάσει κάποιο διαμέρισμα!\n", [Name])
            )
        )
    ),
    writeln("=======================================").



