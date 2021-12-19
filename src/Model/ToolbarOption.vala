namespace ParaPara {
    public enum ToolbarOption {
        ALWAYS_VISIBLE, ALWAYS_HIDDEN, DEPENDS;

        public static ToolbarOption value_of(string name) {
            switch (name) {
              case "always-visible":
                return ALWAYS_VISIBLE;
              case "always-hidden":
                return ALWAYS_HIDDEN;
              default:
              case "depends":
                return DEPENDS;
            }
        }

        public string to_string() {
            switch (this) {
              case ALWAYS_VISIBLE:
                return "always-visible";
              case ALWAYS_HIDDEN:
                return "always-hidden";
              default:
              case DEPENDS:
                return "depends";
            }
        }
    }
}
