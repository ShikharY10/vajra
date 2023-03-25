class SecurityScheme {
  static Scheme get bearer {
    return Scheme("bearer");
  }

}

class Scheme {
  final String name;
  Scheme(this.name);
}

