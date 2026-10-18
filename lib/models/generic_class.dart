class Genericclass<T> {
  T id;
  T name;
  T description;

  Genericclass({
    required this.id,
    required this.name,
    required this.description,
  });

  T getId() => id;
  T getName() => name;
  T getDescription() => description;

  T setId(T newId) => id = newId;
  T setName(T newName) => name = newName;
  T setDescription(T newDescription) => description = newDescription;
}
