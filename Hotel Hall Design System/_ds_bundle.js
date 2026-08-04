/* @ds-bundle: {"format":4,"namespace":"HotelHallDesignSystem_6ae9d5","components":[{"name":"Badge","sourcePath":"components/core/Badge.jsx"},{"name":"Button","sourcePath":"components/core/Button.jsx"},{"name":"Card","sourcePath":"components/core/Card.jsx"},{"name":"CardTitle","sourcePath":"components/core/Card.jsx"},{"name":"CardMeta","sourcePath":"components/core/Card.jsx"},{"name":"IconButton","sourcePath":"components/core/IconButton.jsx"},{"name":"Tabs","sourcePath":"components/core/Tabs.jsx"},{"name":"Tag","sourcePath":"components/core/Tag.jsx"},{"name":"Tooltip","sourcePath":"components/core/Tooltip.jsx"},{"name":"Dialog","sourcePath":"components/feedback/Dialog.jsx"},{"name":"Rating","sourcePath":"components/feedback/Rating.jsx"},{"name":"Toast","sourcePath":"components/feedback/Toast.jsx"},{"name":"Checkbox","sourcePath":"components/forms/Checkbox.jsx"},{"name":"DateField","sourcePath":"components/forms/DateField.jsx"},{"name":"Field","sourcePath":"components/forms/Input.jsx"},{"name":"Input","sourcePath":"components/forms/Input.jsx"},{"name":"Radio","sourcePath":"components/forms/Radio.jsx"},{"name":"RadioGroup","sourcePath":"components/forms/Radio.jsx"},{"name":"Select","sourcePath":"components/forms/Select.jsx"},{"name":"Switch","sourcePath":"components/forms/Switch.jsx"}],"sourceHashes":{"components/core/Badge.jsx":"4b0e6e6fb0ba","components/core/Button.jsx":"aa8ae89a1152","components/core/Card.jsx":"2c614f124b9d","components/core/IconButton.jsx":"3cc3a5db51c2","components/core/Tabs.jsx":"80774d2b5ba7","components/core/Tag.jsx":"f1b7577c2186","components/core/Tooltip.jsx":"db2ef14960bf","components/feedback/Dialog.jsx":"6a860c526c30","components/feedback/Rating.jsx":"8560e8110805","components/feedback/Toast.jsx":"ffacf96ad71c","components/forms/Checkbox.jsx":"9a6cb007bec3","components/forms/DateField.jsx":"cbf29941e1c1","components/forms/Input.jsx":"1f27d40e09b6","components/forms/Radio.jsx":"8fdf7e0d934d","components/forms/Select.jsx":"5d5ad6258510","components/forms/Switch.jsx":"7a3a2b26dadb","ui_kits/guest-app/Chrome.jsx":"fce462b3f02f","ui_kits/guest-app/Screens.jsx":"ba2197fec5aa","ui_kits/website/Checkout.jsx":"5b7d0e5b53c7","ui_kits/website/Home.jsx":"ad3cbb90f3a2","ui_kits/website/Rooms.jsx":"91b4c32c7a4b","ui_kits/website/Shell.jsx":"82e3311c867f","ui_kits/website/Venue.jsx":"83cf6c88d9f1","ui_kits/website/data.jsx":"8bf576d8e2a1"},"inlinedExternals":[],"unexposedExports":[]} */

(() => {

const __ds_ns = (window.HotelHallDesignSystem_6ae9d5 = window.HotelHallDesignSystem_6ae9d5 || {});

const __ds_scope = {};

(__ds_ns.__errors = __ds_ns.__errors || []);

// components/core/Badge.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
const tones = {
  navy: {
    background: "var(--navy-100)",
    color: "var(--navy-700)"
  },
  teal: {
    background: "var(--teal-100)",
    color: "var(--teal-800)"
  },
  gold: {
    background: "var(--gold-200)",
    color: "var(--gold-900)"
  },
  success: {
    background: "var(--success-100)",
    color: "var(--success-700)"
  },
  warning: {
    background: "var(--warning-100)",
    color: "var(--warning-700)"
  },
  danger: {
    background: "var(--danger-100)",
    color: "var(--danger-700)"
  },
  neutral: {
    background: "var(--gray-100)",
    color: "var(--gray-600)"
  },
  solid: {
    background: "var(--surface-navy)",
    color: "var(--text-inverse)"
  }
};
function Badge({
  children,
  tone = "navy",
  size = "md",
  style,
  ...rest
}) {
  return /*#__PURE__*/React.createElement("span", _extends({
    style: {
      display: "inline-flex",
      alignItems: "center",
      gap: 5,
      fontFamily: "var(--font-sans)",
      fontSize: size === "sm" ? "var(--text-2xs)" : "var(--text-xs)",
      fontWeight: "var(--weight-medium)",
      letterSpacing: "var(--tracking-wider)",
      textTransform: "uppercase",
      padding: size === "sm" ? "3px 8px" : "4px 10px",
      borderRadius: "var(--radius-sm)",
      ...tones[tone],
      ...style
    }
  }, rest), children);
}
Object.assign(__ds_scope, { Badge });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/core/Badge.jsx", error: String((e && e.message) || e) }); }

// components/core/Button.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
const base = {
  fontFamily: "var(--font-sans)",
  textTransform: "uppercase",
  letterSpacing: "var(--tracking-wider)",
  fontWeight: "var(--weight-medium)",
  border: "1px solid transparent",
  borderRadius: "var(--radius-control)",
  cursor: "pointer",
  display: "inline-flex",
  alignItems: "center",
  justifyContent: "center",
  gap: "var(--control-gap)",
  whiteSpace: "nowrap",
  transition: "var(--transition-control), transform var(--dur-instant) var(--ease-standard)"
};
const sizes = {
  sm: {
    height: "var(--control-h-sm)",
    padding: "0 14px",
    fontSize: "var(--text-2xs)"
  },
  md: {
    height: "var(--control-h-md)",
    padding: "0 var(--control-pad-x)",
    fontSize: "var(--text-xs)"
  },
  lg: {
    height: "var(--control-h-lg)",
    padding: "0 26px",
    fontSize: "var(--text-sm)"
  }
};
const variants = {
  primary: {
    background: "var(--action-primary)",
    color: "var(--text-inverse)"
  },
  accent: {
    background: "var(--action-accent)",
    color: "var(--text-inverse)"
  },
  gold: {
    background: "var(--action-gold)",
    color: "var(--navy-800)",
    boxShadow: "var(--shadow-inset)"
  },
  secondary: {
    background: "transparent",
    color: "var(--text-heading)",
    borderColor: "var(--border-default)"
  },
  ghost: {
    background: "transparent",
    color: "var(--text-heading)"
  },
  inverse: {
    background: "var(--white)",
    color: "var(--navy-700)"
  }
};
const hovers = {
  primary: {
    background: "var(--action-primary-hover)"
  },
  accent: {
    background: "var(--action-accent-hover)"
  },
  gold: {
    background: "var(--action-gold-hover)"
  },
  secondary: {
    background: "var(--surface-navy-tint)",
    borderColor: "var(--border-strong)"
  },
  ghost: {
    background: "var(--surface-navy-tint)"
  },
  inverse: {
    background: "var(--navy-050)"
  }
};
const actives = {
  primary: {
    background: "var(--action-primary-active)"
  },
  accent: {
    background: "var(--action-accent-active)"
  },
  gold: {
    background: "var(--action-gold-active)"
  },
  secondary: {
    background: "var(--navy-100)"
  },
  ghost: {
    background: "var(--navy-100)"
  },
  inverse: {
    background: "var(--navy-100)"
  }
};
function Button({
  children,
  variant = "primary",
  size = "md",
  disabled = false,
  loading = false,
  fullWidth = false,
  iconLeft,
  iconRight,
  as = "button",
  style,
  ...rest
}) {
  const [hover, setHover] = React.useState(false);
  const [press, setPress] = React.useState(false);
  const Tag = as;
  const off = disabled || loading;
  const s = {
    ...base,
    ...sizes[size],
    ...variants[variant],
    ...(hover && !off ? hovers[variant] : null),
    ...(press && !off ? actives[variant] : null),
    ...(press && !off ? {
      transform: "scale(var(--press-scale))"
    } : null),
    ...(off ? {
      background: "var(--action-disabled-bg)",
      color: "var(--action-disabled-text)",
      borderColor: "transparent",
      boxShadow: "none",
      cursor: "not-allowed"
    } : null),
    ...(fullWidth ? {
      width: "100%"
    } : null),
    ...style
  };
  return /*#__PURE__*/React.createElement(Tag, _extends({
    style: s,
    disabled: as === "button" ? off : undefined,
    onMouseEnter: () => setHover(true),
    onMouseLeave: () => {
      setHover(false);
      setPress(false);
    },
    onMouseDown: () => setPress(true),
    onMouseUp: () => setPress(false)
  }, rest), loading ? /*#__PURE__*/React.createElement("span", {
    style: {
      letterSpacing: ".2em"
    }
  }, "\u2022 \u2022 \u2022") : /*#__PURE__*/React.createElement(React.Fragment, null, iconLeft, children, iconRight));
}
Object.assign(__ds_scope, { Button });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/core/Button.jsx", error: String((e && e.message) || e) }); }

// components/core/Card.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
function Card({
  children,
  image,
  imageAlt = "",
  arch = false,
  featured = false,
  interactive = false,
  padding = "var(--card-pad)",
  style,
  ...rest
}) {
  const [hover, setHover] = React.useState(false);
  const lifted = interactive && hover;
  /* When the caller lays the card out itself (display:grid/flex on style), children are
     rendered directly so that layout applies to them instead of a padding wrapper. */
  const selfLaidOut = style && (style.display === "grid" || style.display === "flex");
  return /*#__PURE__*/React.createElement("div", _extends({
    onMouseEnter: () => setHover(true),
    onMouseLeave: () => setHover(false),
    style: {
      background: featured ? "var(--surface-navy)" : "var(--surface-card)",
      color: featured ? "var(--text-on-navy)" : "var(--text-body)",
      border: featured ? "1px solid transparent" : "1px solid var(--border-subtle)",
      borderRadius: arch ? "var(--arch-top)" : "var(--radius-card)",
      boxShadow: lifted ? "var(--shadow-card-hover)" : "var(--shadow-card)",
      transform: lifted ? "var(--lift-hover)" : "none",
      transition: "var(--transition-card), border-color var(--dur-base) var(--ease-standard)",
      borderColor: lifted && !featured ? "var(--border-strong)" : undefined,
      overflow: "hidden",
      cursor: interactive ? "pointer" : "default",
      ...(selfLaidOut && !image ? {
        padding
      } : null),
      ...style
    }
  }, rest), image ? /*#__PURE__*/React.createElement("div", {
    style: {
      overflow: "hidden",
      aspectRatio: "4 / 3",
      background: "var(--sand-100)"
    }
  }, /*#__PURE__*/React.createElement("img", {
    src: image,
    alt: imageAlt,
    style: {
      width: "100%",
      height: "100%",
      objectFit: "cover",
      display: "block",
      transition: "transform var(--dur-slow) var(--ease-standard)",
      transform: lifted ? "scale(1.03)" : "none"
    }
  })) : null, selfLaidOut && !image ? children : /*#__PURE__*/React.createElement("div", {
    style: {
      padding
    }
  }, children));
}
function CardTitle({
  children,
  style,
  ...rest
}) {
  return /*#__PURE__*/React.createElement("div", _extends({
    style: {
      fontFamily: "var(--font-serif)",
      fontSize: "var(--serif-md)",
      lineHeight: 1.25,
      color: "inherit",
      ...style
    }
  }, rest), children);
}
function CardMeta({
  children,
  style,
  ...rest
}) {
  return /*#__PURE__*/React.createElement("div", _extends({
    style: {
      fontFamily: "var(--font-sans)",
      fontSize: "var(--text-sm)",
      color: "var(--text-muted)",
      display: "flex",
      gap: 6,
      alignItems: "center",
      flexWrap: "wrap",
      ...style
    }
  }, rest), children);
}
Object.assign(__ds_scope, { Card, CardTitle, CardMeta });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/core/Card.jsx", error: String((e && e.message) || e) }); }

// components/core/IconButton.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
const sizes = {
  sm: 32,
  md: 40,
  lg: 48
};
const glyph = {
  sm: 16,
  md: 20,
  lg: 22
};
function IconButton({
  icon,
  label,
  variant = "ghost",
  size = "md",
  disabled = false,
  round = false,
  style,
  ...rest
}) {
  const [hover, setHover] = React.useState(false);
  const tone = {
    ghost: {
      background: "transparent",
      color: "var(--text-heading)",
      border: "1px solid transparent"
    },
    outline: {
      background: "var(--surface-card)",
      color: "var(--text-heading)",
      border: "1px solid var(--border-default)"
    },
    solid: {
      background: "var(--action-primary)",
      color: "var(--text-inverse)",
      border: "1px solid transparent"
    },
    glass: {
      background: "var(--surface-glass)",
      color: "var(--navy-800)",
      border: "1px solid rgba(255,255,255,.5)",
      backdropFilter: "var(--blur-glass)"
    }
  }[variant];
  const hoverTone = {
    ghost: {
      background: "var(--surface-navy-tint)"
    },
    outline: {
      borderColor: "var(--border-strong)",
      background: "var(--surface-navy-tint)"
    },
    solid: {
      background: "var(--action-primary-hover)"
    },
    glass: {
      background: "rgba(255,255,255,.92)"
    }
  }[variant];
  return /*#__PURE__*/React.createElement("button", _extends({
    "aria-label": label,
    title: label,
    disabled: disabled,
    onMouseEnter: () => setHover(true),
    onMouseLeave: () => setHover(false),
    style: {
      width: sizes[size],
      height: sizes[size],
      padding: 0,
      display: "inline-flex",
      alignItems: "center",
      justifyContent: "center",
      borderRadius: round ? "var(--radius-pill)" : "var(--radius-control)",
      cursor: disabled ? "not-allowed" : "pointer",
      fontSize: glyph[size],
      lineHeight: 0,
      transition: "var(--transition-control)",
      ...tone,
      ...(hover && !disabled ? hoverTone : null),
      ...(disabled ? {
        background: "var(--action-disabled-bg)",
        color: "var(--action-disabled-text)",
        borderColor: "transparent"
      } : null),
      ...style
    }
  }, rest), icon);
}
Object.assign(__ds_scope, { IconButton });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/core/IconButton.jsx", error: String((e && e.message) || e) }); }

// components/core/Tabs.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
function Tabs({
  items,
  value,
  onChange,
  variant = "underline",
  style,
  ...rest
}) {
  const [internal, setInternal] = React.useState(value ?? items?.[0]?.id);
  const active = value ?? internal;
  const select = id => {
    setInternal(id);
    onChange && onChange(id);
  };
  const underline = variant === "underline";
  return /*#__PURE__*/React.createElement("div", _extends({
    role: "tablist",
    style: {
      display: "flex",
      gap: underline ? 28 : 4,
      borderBottom: underline ? "1px solid var(--border-subtle)" : "none",
      background: underline ? "transparent" : "var(--surface-sunken)",
      padding: underline ? 0 : 4,
      borderRadius: underline ? 0 : "var(--radius-control)",
      ...style
    }
  }, rest), items.map(it => {
    const on = it.id === active;
    return /*#__PURE__*/React.createElement("button", {
      key: it.id,
      role: "tab",
      "aria-selected": on,
      onClick: () => select(it.id),
      style: {
        border: 0,
        cursor: "pointer",
        background: underline ? "none" : on ? "var(--surface-card)" : "transparent",
        fontFamily: "var(--font-sans)",
        fontSize: "var(--text-xs)",
        letterSpacing: "var(--tracking-wider)",
        textTransform: "uppercase",
        fontWeight: "var(--weight-medium)",
        color: on ? "var(--text-heading)" : "var(--text-muted)",
        padding: underline ? "0 0 12px" : "8px 16px",
        borderRadius: underline ? 0 : "var(--radius-sm)",
        boxShadow: underline ? on ? "inset 0 -2px 0 var(--teal-700)" : "none" : on ? "var(--shadow-xs)" : "none",
        transition: "var(--transition-control)"
      }
    }, it.label, it.count != null ? /*#__PURE__*/React.createElement("span", {
      style: {
        color: "var(--text-subtle)",
        marginLeft: 6
      }
    }, it.count) : null);
  }));
}
Object.assign(__ds_scope, { Tabs });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/core/Tabs.jsx", error: String((e && e.message) || e) }); }

// components/core/Tag.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
function Tag({
  children,
  icon,
  selected = false,
  onRemove,
  onClick,
  style,
  ...rest
}) {
  const [hover, setHover] = React.useState(false);
  const clickable = !!onClick;
  return /*#__PURE__*/React.createElement("span", _extends({
    onClick: onClick,
    onMouseEnter: () => setHover(true),
    onMouseLeave: () => setHover(false),
    style: {
      display: "inline-flex",
      alignItems: "center",
      gap: 6,
      fontFamily: "var(--font-sans)",
      fontSize: "var(--text-sm)",
      letterSpacing: "var(--tracking-wide)",
      padding: "6px 12px",
      borderRadius: "var(--radius-pill)",
      cursor: clickable ? "pointer" : "default",
      transition: "var(--transition-control)",
      background: selected ? "var(--teal-100)" : hover && clickable ? "var(--surface-navy-tint)" : "var(--surface-card)",
      color: selected ? "var(--teal-800)" : "var(--text-body)",
      border: selected ? "1.5px solid var(--teal-600)" : "1px solid var(--border-default)",
      ...style
    }
  }, rest), icon, children, onRemove ? /*#__PURE__*/React.createElement("button", {
    onClick: e => {
      e.stopPropagation();
      onRemove(e);
    },
    "aria-label": "Remove",
    style: {
      border: 0,
      background: "none",
      padding: 0,
      marginLeft: 2,
      cursor: "pointer",
      color: "var(--text-subtle)",
      fontSize: 14,
      lineHeight: 1
    }
  }, "\xD7") : null);
}
Object.assign(__ds_scope, { Tag });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/core/Tag.jsx", error: String((e && e.message) || e) }); }

// components/core/Tooltip.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
function Tooltip({
  children,
  label,
  placement = "top",
  style,
  ...rest
}) {
  const [open, setOpen] = React.useState(false);
  const pos = {
    top: {
      bottom: "calc(100% + 8px)",
      left: "50%",
      transform: "translateX(-50%)"
    },
    bottom: {
      top: "calc(100% + 8px)",
      left: "50%",
      transform: "translateX(-50%)"
    },
    left: {
      right: "calc(100% + 8px)",
      top: "50%",
      transform: "translateY(-50%)"
    },
    right: {
      left: "calc(100% + 8px)",
      top: "50%",
      transform: "translateY(-50%)"
    }
  }[placement];
  return /*#__PURE__*/React.createElement("span", _extends({
    onMouseEnter: () => setOpen(true),
    onMouseLeave: () => setOpen(false),
    onFocus: () => setOpen(true),
    onBlur: () => setOpen(false),
    style: {
      position: "relative",
      display: "inline-flex",
      ...style
    }
  }, rest), children, /*#__PURE__*/React.createElement("span", {
    role: "tooltip",
    style: {
      position: "absolute",
      ...pos,
      background: "var(--navy-800)",
      color: "var(--text-on-navy)",
      fontFamily: "var(--font-sans)",
      fontSize: "var(--text-xs)",
      letterSpacing: "var(--tracking-wide)",
      padding: "6px 10px",
      borderRadius: "var(--radius-sm)",
      boxShadow: "var(--shadow-md)",
      whiteSpace: "nowrap",
      pointerEvents: "none",
      opacity: open ? 1 : 0,
      transition: `opacity var(--dur-fast) var(--ease-standard)`,
      zIndex: 20
    }
  }, label));
}
Object.assign(__ds_scope, { Tooltip });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/core/Tooltip.jsx", error: String((e && e.message) || e) }); }

// components/feedback/Dialog.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
function Dialog({
  open = true,
  title,
  eyebrow,
  children,
  footer,
  onClose,
  width = 480,
  style,
  ...rest
}) {
  if (!open) return null;
  return /*#__PURE__*/React.createElement("div", {
    style: {
      position: "absolute",
      inset: 0,
      zIndex: 40,
      background: "var(--surface-overlay)",
      display: "flex",
      alignItems: "center",
      justifyContent: "center",
      padding: 24,
      animation: `hhFade var(--dur-slow) var(--ease-standard)`
    },
    onClick: onClose
  }, /*#__PURE__*/React.createElement("style", null, "@keyframes hhFade{from{opacity:0}to{opacity:1}}@keyframes hhRise{from{opacity:0;transform:translateY(8px)}to{opacity:1;transform:none}}"), /*#__PURE__*/React.createElement("div", _extends({
    role: "dialog",
    "aria-modal": "true",
    onClick: e => e.stopPropagation(),
    style: {
      width,
      maxWidth: "100%",
      background: "var(--surface-card)",
      borderRadius: "var(--radius-modal)",
      boxShadow: "var(--shadow-modal)",
      animation: `hhRise var(--dur-slow) var(--ease-standard)`,
      overflow: "hidden",
      ...style
    }
  }, rest), /*#__PURE__*/React.createElement("div", {
    style: {
      padding: "var(--card-pad-lg)",
      paddingBottom: 0
    }
  }, eyebrow ? /*#__PURE__*/React.createElement("div", {
    style: {
      fontFamily: "var(--font-sans)",
      fontSize: "var(--eyebrow-size)",
      letterSpacing: "var(--eyebrow-tracking)",
      textTransform: "uppercase",
      color: "var(--text-gold)",
      marginBottom: 10
    }
  }, eyebrow) : null, title ? /*#__PURE__*/React.createElement("div", {
    style: {
      fontFamily: "var(--font-display)",
      textTransform: "uppercase",
      letterSpacing: "var(--display-tracking)",
      fontSize: "var(--display-sm)",
      color: "var(--text-heading)",
      lineHeight: 1.15
    }
  }, title) : null, /*#__PURE__*/React.createElement("div", {
    style: {
      fontFamily: "var(--font-sans)",
      fontSize: "var(--text-md)",
      color: "var(--text-body)",
      marginTop: 12
    }
  }, children)), /*#__PURE__*/React.createElement("div", {
    style: {
      display: "flex",
      justifyContent: "flex-end",
      gap: 8,
      padding: "var(--card-pad-lg)"
    }
  }, footer)));
}
Object.assign(__ds_scope, { Dialog });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/feedback/Dialog.jsx", error: String((e && e.message) || e) }); }

// components/feedback/Rating.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/** Star rating. The one place a filled icon is allowed, in gold. */
function Rating({
  value = 0,
  max = 5,
  size = 16,
  count,
  label,
  style,
  ...rest
}) {
  const stars = Array.from({
    length: max
  }, (_, i) => {
    const fill = Math.max(0, Math.min(1, value - i));
    return /*#__PURE__*/React.createElement("span", {
      key: i,
      style: {
        position: "relative",
        display: "inline-block",
        width: size,
        height: size,
        lineHeight: 1
      }
    }, /*#__PURE__*/React.createElement("span", {
      style: {
        position: "absolute",
        inset: 0,
        color: "var(--gray-300)",
        fontSize: size,
        lineHeight: 1
      }
    }, "\u2605"), /*#__PURE__*/React.createElement("span", {
      style: {
        position: "absolute",
        inset: 0,
        overflow: "hidden",
        width: `${fill * 100}%`,
        color: "var(--gold-600)",
        fontSize: size,
        lineHeight: 1
      }
    }, "\u2605"));
  });
  return /*#__PURE__*/React.createElement("span", _extends({
    style: {
      display: "inline-flex",
      alignItems: "center",
      gap: 6,
      fontFamily: "var(--font-sans)",
      ...style
    }
  }, rest), /*#__PURE__*/React.createElement("span", {
    style: {
      display: "inline-flex",
      gap: 2
    }
  }, stars), label !== false ? /*#__PURE__*/React.createElement("span", {
    style: {
      fontSize: "var(--text-sm)",
      color: "var(--text-body)"
    }
  }, value.toFixed(1)) : null, count != null ? /*#__PURE__*/React.createElement("span", {
    style: {
      fontSize: "var(--text-sm)",
      color: "var(--text-muted)"
    }
  }, "(", count, ")") : null);
}
Object.assign(__ds_scope, { Rating });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/feedback/Rating.jsx", error: String((e && e.message) || e) }); }

// components/feedback/Toast.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
const tones = {
  info: {
    accent: "var(--navy-600)",
    bg: "var(--surface-navy)",
    fg: "var(--text-on-navy)"
  },
  success: {
    accent: "var(--success-500)",
    bg: "var(--surface-navy)",
    fg: "var(--text-on-navy)"
  },
  warning: {
    accent: "var(--warning-500)",
    bg: "var(--surface-navy)",
    fg: "var(--text-on-navy)"
  },
  danger: {
    accent: "var(--danger-500)",
    bg: "var(--surface-navy)",
    fg: "var(--text-on-navy)"
  }
};
function Toast({
  title,
  message,
  tone = "info",
  action,
  onDismiss,
  style,
  ...rest
}) {
  const t = tones[tone];
  return /*#__PURE__*/React.createElement("div", _extends({
    role: "status",
    style: {
      display: "flex",
      alignItems: "flex-start",
      gap: 12,
      minWidth: 300,
      maxWidth: 420,
      background: t.bg,
      color: t.fg,
      borderRadius: "var(--radius-lg)",
      boxShadow: "var(--shadow-lg)",
      padding: "14px 16px",
      fontFamily: "var(--font-sans)",
      ...style
    }
  }, rest), /*#__PURE__*/React.createElement("span", {
    style: {
      flex: "0 0 auto",
      width: 3,
      alignSelf: "stretch",
      borderRadius: 2,
      background: t.accent
    }
  }), /*#__PURE__*/React.createElement("span", {
    style: {
      flex: 1
    }
  }, title ? /*#__PURE__*/React.createElement("span", {
    style: {
      display: "block",
      fontSize: "var(--text-xs)",
      letterSpacing: "var(--tracking-wider)",
      textTransform: "uppercase",
      color: "var(--white)"
    }
  }, title) : null, message ? /*#__PURE__*/React.createElement("span", {
    style: {
      display: "block",
      fontSize: "var(--text-sm)",
      marginTop: 4,
      opacity: .85
    }
  }, message) : null, action ? /*#__PURE__*/React.createElement("span", {
    style: {
      display: "inline-block",
      marginTop: 10
    }
  }, action) : null), onDismiss ? /*#__PURE__*/React.createElement("button", {
    onClick: onDismiss,
    "aria-label": "Dismiss",
    style: {
      border: 0,
      background: "none",
      color: "inherit",
      opacity: .6,
      cursor: "pointer",
      fontSize: 15,
      lineHeight: 1,
      padding: 0
    }
  }, "\xD7") : null);
}
Object.assign(__ds_scope, { Toast });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/feedback/Toast.jsx", error: String((e && e.message) || e) }); }

// components/forms/Checkbox.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
function Checkbox({
  label,
  description,
  checked,
  defaultChecked,
  onChange,
  disabled,
  style,
  ...rest
}) {
  const [internal, setInternal] = React.useState(defaultChecked || false);
  const on = checked ?? internal;
  const toggle = () => {
    if (disabled) return;
    setInternal(!on);
    onChange && onChange(!on);
  };
  return /*#__PURE__*/React.createElement("label", _extends({
    onClick: toggle,
    style: {
      display: "flex",
      gap: 10,
      alignItems: description ? "flex-start" : "center",
      fontFamily: "var(--font-sans)",
      fontSize: "var(--text-md)",
      color: disabled ? "var(--action-disabled-text)" : "var(--text-body)",
      cursor: disabled ? "not-allowed" : "pointer",
      ...style
    }
  }, rest), /*#__PURE__*/React.createElement("span", {
    style: {
      flex: "0 0 auto",
      width: 18,
      height: 18,
      marginTop: description ? 2 : 0,
      borderRadius: "var(--radius-xs)",
      border: `1.5px solid ${on ? "var(--teal-700)" : "var(--border-default)"}`,
      background: disabled ? "var(--action-disabled-bg)" : on ? "var(--teal-700)" : "var(--surface-card)",
      color: "#fff",
      display: "flex",
      alignItems: "center",
      justifyContent: "center",
      fontSize: 12,
      lineHeight: 1,
      transition: "var(--transition-control)"
    }
  }, on ? "✓" : ""), /*#__PURE__*/React.createElement("span", null, label, description ? /*#__PURE__*/React.createElement("span", {
    style: {
      display: "block",
      fontSize: "var(--text-sm)",
      color: "var(--text-muted)",
      marginTop: 2
    }
  }, description) : null));
}
Object.assign(__ds_scope, { Checkbox });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/forms/Checkbox.jsx", error: String((e && e.message) || e) }); }

// components/forms/DateField.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/** Check-in / check-out pair. Cosmetic: a real datepicker is out of scope. */
function DateField({
  label = "Dates",
  checkIn,
  checkOut,
  nights,
  onClick,
  size = "md",
  style,
  ...rest
}) {
  const [hover, setHover] = React.useState(false);
  const h = size === "lg" ? "var(--control-h-lg)" : "var(--control-h-md)";
  const cell = (cap, val) => /*#__PURE__*/React.createElement("span", {
    style: {
      display: "flex",
      flexDirection: "column",
      justifyContent: "center",
      flex: 1,
      minWidth: 0,
      padding: "0 12px"
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      fontSize: "var(--text-2xs)",
      letterSpacing: "var(--tracking-wider)",
      textTransform: "uppercase",
      color: "var(--text-subtle)"
    }
  }, cap), /*#__PURE__*/React.createElement("span", {
    style: {
      fontSize: "var(--text-sm)",
      color: val ? "var(--text-body)" : "var(--text-subtle)",
      whiteSpace: "nowrap",
      overflow: "hidden",
      textOverflow: "ellipsis"
    }
  }, val || "Add date"));
  return /*#__PURE__*/React.createElement("div", _extends({
    style: {
      fontFamily: "var(--font-sans)",
      ...style
    }
  }, rest), label ? /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: "var(--text-xs)",
      letterSpacing: "var(--tracking-wider)",
      textTransform: "uppercase",
      color: "var(--text-muted)",
      marginBottom: 6
    }
  }, label) : null, /*#__PURE__*/React.createElement("div", {
    onClick: onClick,
    onMouseEnter: () => setHover(true),
    onMouseLeave: () => setHover(false),
    style: {
      display: "flex",
      alignItems: "stretch",
      height: `calc(${h} + 8px)`,
      background: "var(--surface-card)",
      border: `1px solid ${hover ? "var(--border-strong)" : "var(--border-default)"}`,
      borderRadius: "var(--radius-control)",
      cursor: "pointer",
      transition: "var(--transition-control)"
    }
  }, cell("Check in", checkIn), /*#__PURE__*/React.createElement("span", {
    style: {
      width: 1,
      background: "var(--border-subtle)",
      margin: "8px 0"
    }
  }), cell("Check out", checkOut), nights ? /*#__PURE__*/React.createElement("span", {
    style: {
      display: "flex",
      alignItems: "center",
      padding: "0 14px",
      fontSize: "var(--text-xs)",
      letterSpacing: "var(--tracking-wide)",
      color: "var(--text-accent)",
      borderLeft: "1px solid var(--border-subtle)"
    }
  }, nights, " ", nights === 1 ? "night" : "nights") : null));
}
Object.assign(__ds_scope, { DateField });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/forms/DateField.jsx", error: String((e && e.message) || e) }); }

// components/forms/Input.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
function Field({
  label,
  hint,
  error,
  required,
  htmlFor,
  children,
  style
}) {
  return /*#__PURE__*/React.createElement("label", {
    htmlFor: htmlFor,
    style: {
      display: "block",
      fontFamily: "var(--font-sans)",
      ...style
    }
  }, label ? /*#__PURE__*/React.createElement("span", {
    style: {
      display: "block",
      fontSize: "var(--text-xs)",
      letterSpacing: "var(--tracking-wider)",
      textTransform: "uppercase",
      color: "var(--text-muted)",
      marginBottom: 6
    }
  }, label, required ? /*#__PURE__*/React.createElement("span", {
    style: {
      color: "var(--gold-700)"
    }
  }, " *") : null) : null, children, error ? /*#__PURE__*/React.createElement("span", {
    style: {
      display: "block",
      fontSize: "var(--text-xs)",
      color: "var(--danger-700)",
      marginTop: 6
    }
  }, error) : hint ? /*#__PURE__*/React.createElement("span", {
    style: {
      display: "block",
      fontSize: "var(--text-xs)",
      color: "var(--text-subtle)",
      marginTop: 6
    }
  }, hint) : null);
}
function Input({
  label,
  hint,
  error,
  required,
  size = "md",
  iconLeft,
  iconRight,
  disabled,
  style,
  wrapperStyle,
  ...rest
}) {
  const [focus, setFocus] = React.useState(false);
  const h = size === "sm" ? "var(--control-h-sm)" : size === "lg" ? "var(--control-h-lg)" : "var(--control-h-md)";
  const box = /*#__PURE__*/React.createElement("span", {
    style: {
      display: "flex",
      alignItems: "center",
      gap: 8,
      height: h,
      padding: "0 12px",
      background: disabled ? "var(--action-disabled-bg)" : "var(--surface-card)",
      border: `1px solid ${error ? "var(--danger-500)" : focus ? "var(--teal-600)" : "var(--border-default)"}`,
      borderRadius: "var(--radius-control)",
      boxShadow: focus ? "var(--shadow-focus)" : "none",
      transition: "var(--transition-control)",
      color: "var(--text-subtle)",
      ...wrapperStyle
    }
  }, iconLeft, /*#__PURE__*/React.createElement("input", _extends({
    disabled: disabled,
    onFocus: () => setFocus(true),
    onBlur: () => setFocus(false),
    style: {
      flex: 1,
      minWidth: 0,
      border: 0,
      outline: "none",
      background: "transparent",
      fontFamily: "var(--font-sans)",
      fontSize: size === "sm" ? "var(--text-sm)" : "var(--text-md)",
      color: disabled ? "var(--action-disabled-text)" : "var(--text-body)",
      ...style
    }
  }, rest)), iconRight);
  if (!label && !hint && !error) return box;
  return /*#__PURE__*/React.createElement(Field, {
    label: label,
    hint: hint,
    error: error,
    required: required
  }, box);
}
Object.assign(__ds_scope, { Field, Input });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/forms/Input.jsx", error: String((e && e.message) || e) }); }

// components/forms/Radio.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
function Radio({
  label,
  description,
  checked,
  name,
  onChange,
  disabled,
  value,
  style,
  ...rest
}) {
  return /*#__PURE__*/React.createElement("label", _extends({
    onClick: () => !disabled && onChange && onChange(value),
    style: {
      display: "flex",
      gap: 10,
      alignItems: description ? "flex-start" : "center",
      fontFamily: "var(--font-sans)",
      fontSize: "var(--text-md)",
      color: disabled ? "var(--action-disabled-text)" : "var(--text-body)",
      cursor: disabled ? "not-allowed" : "pointer",
      ...style
    }
  }, rest), /*#__PURE__*/React.createElement("span", {
    style: {
      flex: "0 0 auto",
      width: 18,
      height: 18,
      marginTop: description ? 2 : 0,
      borderRadius: "var(--radius-pill)",
      border: `1.5px solid ${checked ? "var(--teal-700)" : "var(--border-default)"}`,
      background: disabled ? "var(--action-disabled-bg)" : "var(--surface-card)",
      display: "flex",
      alignItems: "center",
      justifyContent: "center",
      transition: "var(--transition-control)"
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      width: 9,
      height: 9,
      borderRadius: "var(--radius-pill)",
      background: checked ? "var(--teal-700)" : "transparent",
      transition: "var(--transition-control)"
    }
  })), /*#__PURE__*/React.createElement("span", null, label, description ? /*#__PURE__*/React.createElement("span", {
    style: {
      display: "block",
      fontSize: "var(--text-sm)",
      color: "var(--text-muted)",
      marginTop: 2
    }
  }, description) : null));
}
function RadioGroup({
  label,
  name,
  value,
  options = [],
  onChange,
  style
}) {
  return /*#__PURE__*/React.createElement("div", {
    style: {
      fontFamily: "var(--font-sans)",
      ...style
    }
  }, label ? /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: "var(--text-xs)",
      letterSpacing: "var(--tracking-wider)",
      textTransform: "uppercase",
      color: "var(--text-muted)",
      marginBottom: 10
    }
  }, label) : null, /*#__PURE__*/React.createElement("div", {
    style: {
      display: "flex",
      flexDirection: "column",
      gap: 10
    }
  }, options.map(o => /*#__PURE__*/React.createElement(Radio, {
    key: o.value,
    name: name,
    value: o.value,
    label: o.label,
    description: o.description,
    checked: value === o.value,
    onChange: onChange
  }))));
}
Object.assign(__ds_scope, { Radio, RadioGroup });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/forms/Radio.jsx", error: String((e && e.message) || e) }); }

// components/forms/Select.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
function Select({
  label,
  hint,
  error,
  required,
  options = [],
  size = "md",
  disabled,
  style,
  ...rest
}) {
  const [focus, setFocus] = React.useState(false);
  const h = size === "sm" ? "var(--control-h-sm)" : size === "lg" ? "var(--control-h-lg)" : "var(--control-h-md)";
  const control = /*#__PURE__*/React.createElement("span", {
    style: {
      position: "relative",
      display: "block"
    }
  }, /*#__PURE__*/React.createElement("select", _extends({
    disabled: disabled,
    onFocus: () => setFocus(true),
    onBlur: () => setFocus(false),
    style: {
      width: "100%",
      height: h,
      padding: "0 34px 0 12px",
      appearance: "none",
      fontFamily: "var(--font-sans)",
      fontSize: size === "sm" ? "var(--text-sm)" : "var(--text-md)",
      color: disabled ? "var(--action-disabled-text)" : "var(--text-body)",
      background: disabled ? "var(--action-disabled-bg)" : "var(--surface-card)",
      border: `1px solid ${error ? "var(--danger-500)" : focus ? "var(--teal-600)" : "var(--border-default)"}`,
      borderRadius: "var(--radius-control)",
      boxShadow: focus ? "var(--shadow-focus)" : "none",
      transition: "var(--transition-control)",
      outline: "none",
      ...style
    }
  }, rest), options.map(o => {
    const v = typeof o === "string" ? o : o.value;
    const l = typeof o === "string" ? o : o.label;
    return /*#__PURE__*/React.createElement("option", {
      key: v,
      value: v
    }, l);
  })), /*#__PURE__*/React.createElement("span", {
    "aria-hidden": "true",
    style: {
      position: "absolute",
      right: 12,
      top: "50%",
      transform: "translateY(-50%)",
      pointerEvents: "none",
      color: "var(--text-subtle)",
      fontSize: 11
    }
  }, "\u25BE"));
  if (!label && !hint && !error) return control;
  return /*#__PURE__*/React.createElement(__ds_scope.Field, {
    label: label,
    hint: hint,
    error: error,
    required: required
  }, control);
}
Object.assign(__ds_scope, { Select });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/forms/Select.jsx", error: String((e && e.message) || e) }); }

// components/forms/Switch.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
function Switch({
  label,
  checked,
  defaultChecked,
  onChange,
  disabled,
  style,
  ...rest
}) {
  const [internal, setInternal] = React.useState(defaultChecked || false);
  const on = checked ?? internal;
  const toggle = () => {
    if (disabled) return;
    setInternal(!on);
    onChange && onChange(!on);
  };
  return /*#__PURE__*/React.createElement("label", _extends({
    onClick: toggle,
    style: {
      display: "inline-flex",
      gap: 10,
      alignItems: "center",
      fontFamily: "var(--font-sans)",
      fontSize: "var(--text-md)",
      color: disabled ? "var(--action-disabled-text)" : "var(--text-body)",
      cursor: disabled ? "not-allowed" : "pointer",
      ...style
    }
  }, rest), /*#__PURE__*/React.createElement("span", {
    role: "switch",
    "aria-checked": on,
    style: {
      width: 40,
      height: 22,
      borderRadius: "var(--radius-pill)",
      padding: 2,
      background: disabled ? "var(--action-disabled-bg)" : on ? "var(--teal-700)" : "var(--gray-300)",
      transition: `background-color var(--dur-fast) var(--ease-standard)`,
      display: "inline-flex",
      alignItems: "center"
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      width: 18,
      height: 18,
      borderRadius: "var(--radius-pill)",
      background: "var(--white)",
      boxShadow: "var(--shadow-xs)",
      transform: on ? "translateX(18px)" : "translateX(0)",
      transition: `transform var(--dur-fast) var(--ease-standard)`
    }
  })), label);
}
Object.assign(__ds_scope, { Switch });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/forms/Switch.jsx", error: String((e && e.message) || e) }); }

// ui_kits/guest-app/Chrome.jsx
try { (() => {
const {
  Button,
  Card,
  CardTitle,
  CardMeta,
  Badge,
  Tag,
  Tabs,
  Switch,
  Rating,
  IconButton,
  Input,
  Toast
} = window.HotelHallDesignSystem_6ae9d5;
function Icon({
  name,
  size = 20,
  style
}) {
  const r = React.useRef(null);
  React.useEffect(() => {
    if (r.current && window.lucide) {
      r.current.innerHTML = "";
      const el = document.createElement("i");
      el.setAttribute("data-lucide", name);
      r.current.appendChild(el);
      window.lucide.createIcons({
        attrs: {
          width: size,
          height: size,
          "stroke-width": 1.5
        },
        nameAttr: "data-lucide"
      });
    }
  }, [name, size]);
  return /*#__PURE__*/React.createElement("span", {
    ref: r,
    style: {
      display: "inline-flex",
      lineHeight: 0,
      ...style
    }
  });
}
function Photo({
  label = "Photography",
  ratio = "16 / 9",
  tone = "sand",
  radius = "var(--radius-image)",
  children,
  style
}) {
  const bg = {
    sand: "var(--sand-100)",
    navy: "var(--navy-100)",
    deep: "var(--navy-700)"
  }[tone];
  return /*#__PURE__*/React.createElement("div", {
    style: {
      position: "relative",
      aspectRatio: ratio,
      background: bg,
      borderRadius: radius,
      overflow: "hidden",
      display: "flex",
      alignItems: "center",
      justifyContent: "center",
      ...style
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      fontFamily: "var(--font-sans)",
      fontSize: 10,
      letterSpacing: ".18em",
      textTransform: "uppercase",
      color: tone === "deep" ? "rgba(255,255,255,.35)" : "var(--text-subtle)"
    }
  }, label), children);
}
function StatusBar({
  dark
}) {
  return /*#__PURE__*/React.createElement("div", {
    style: {
      height: 44,
      display: "flex",
      alignItems: "center",
      justifyContent: "space-between",
      padding: "0 22px",
      fontFamily: "var(--font-sans)",
      fontSize: 13,
      fontWeight: 500,
      color: dark ? "#fff" : "var(--navy-800)"
    }
  }, /*#__PURE__*/React.createElement("span", null, "9:41"), /*#__PURE__*/React.createElement("span", {
    style: {
      display: "flex",
      gap: 6,
      alignItems: "center",
      opacity: .9
    }
  }, /*#__PURE__*/React.createElement(Icon, {
    name: "signal",
    size: 14
  }), /*#__PURE__*/React.createElement(Icon, {
    name: "wifi",
    size: 14
  }), /*#__PURE__*/React.createElement(Icon, {
    name: "battery-full",
    size: 16
  })));
}
const TABS = [{
  id: "stay",
  label: "Stay",
  icon: "bed-double"
}, {
  id: "key",
  label: "Key",
  icon: "key-round"
}, {
  id: "services",
  label: "Services",
  icon: "concierge-bell"
}];
function TabBar({
  route,
  go
}) {
  return /*#__PURE__*/React.createElement("div", {
    style: {
      borderTop: "1px solid var(--border-subtle)",
      background: "rgba(251,250,247,.96)",
      backdropFilter: "var(--blur-glass)",
      padding: "8px 12px 22px",
      display: "flex"
    }
  }, TABS.map(t => {
    const on = route === t.id;
    return /*#__PURE__*/React.createElement("button", {
      key: t.id,
      onClick: () => go(t.id),
      style: {
        flex: 1,
        border: 0,
        background: "none",
        cursor: "pointer",
        display: "flex",
        flexDirection: "column",
        alignItems: "center",
        gap: 5,
        padding: "8px 0",
        color: on ? "var(--teal-700)" : "var(--text-subtle)"
      }
    }, /*#__PURE__*/React.createElement(Icon, {
      name: t.icon,
      size: 22
    }), /*#__PURE__*/React.createElement("span", {
      style: {
        fontFamily: "var(--font-sans)",
        fontSize: 10,
        letterSpacing: "var(--tracking-wider)",
        textTransform: "uppercase",
        fontWeight: on ? 500 : 400
      }
    }, t.label));
  }));
}
function AppBar({
  title,
  subtitle,
  action
}) {
  return /*#__PURE__*/React.createElement("div", {
    style: {
      padding: "6px 20px 16px",
      display: "flex",
      alignItems: "flex-end",
      justifyContent: "space-between",
      gap: 12
    }
  }, /*#__PURE__*/React.createElement("div", null, subtitle ? /*#__PURE__*/React.createElement("div", {
    className: "hh-eyebrow",
    style: {
      fontSize: 10
    }
  }, subtitle) : null, /*#__PURE__*/React.createElement("div", {
    style: {
      fontFamily: "var(--font-display)",
      fontSize: 24,
      letterSpacing: ".05em",
      textTransform: "uppercase",
      color: "var(--text-heading)",
      marginTop: subtitle ? 8 : 0
    }
  }, title)), action);
}
Object.assign(window, {
  Icon,
  Photo,
  StatusBar,
  TabBar,
  AppBar,
  TABS
});
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/guest-app/Chrome.jsx", error: String((e && e.message) || e) }); }

// ui_kits/guest-app/Screens.jsx
try { (() => {
const {
  Button,
  Card,
  CardTitle,
  CardMeta,
  Badge,
  Tag,
  Switch,
  Rating,
  IconButton,
  Tabs,
  Checkbox
} = window.HotelHallDesignSystem_6ae9d5;
function StayScreen({
  go
}) {
  return /*#__PURE__*/React.createElement("div", {
    style: {
      padding: "0 20px 24px"
    }
  }, /*#__PURE__*/React.createElement(AppBar, {
    subtitle: "Reservation 4821-HH",
    title: "Your stay",
    action: /*#__PURE__*/React.createElement(IconButton, {
      icon: /*#__PURE__*/React.createElement(Icon, {
        name: "bell",
        size: 18
      }),
      label: "Notifications",
      variant: "outline",
      size: "sm"
    })
  }), /*#__PURE__*/React.createElement(Card, {
    padding: "0",
    style: {
      overflow: "hidden"
    }
  }, /*#__PURE__*/React.createElement(Photo, {
    tone: "deep",
    ratio: "16 / 10",
    radius: "0",
    label: "Harbour Suite"
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      position: "absolute",
      inset: 0,
      background: "var(--scrim-bottom)"
    }
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      position: "absolute",
      left: 18,
      bottom: 14,
      color: "#fff"
    }
  }, /*#__PURE__*/React.createElement("div", {
    className: "hh-eyebrow",
    style: {
      color: "var(--gold-400)",
      fontSize: 10
    }
  }, "Room 812"), /*#__PURE__*/React.createElement("div", {
    style: {
      fontFamily: "var(--font-serif)",
      fontSize: 22,
      marginTop: 4
    }
  }, "Harbour Suite")), /*#__PURE__*/React.createElement("div", {
    style: {
      position: "absolute",
      top: 14,
      right: 14
    }
  }, /*#__PURE__*/React.createElement(Badge, {
    tone: "solid",
    size: "sm"
  }, "Checked in"))), /*#__PURE__*/React.createElement("div", {
    style: {
      padding: "18px 18px 20px"
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      display: "flex",
      justifyContent: "space-between",
      fontFamily: "var(--font-sans)",
      fontSize: "var(--text-sm)"
    }
  }, [["Check in", "Aug 12 · 3:00 PM"], ["Check out", "Aug 15 · 11:00 AM"]].map(([l, v]) => /*#__PURE__*/React.createElement("div", {
    key: l
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: 10,
      letterSpacing: "var(--tracking-wider)",
      textTransform: "uppercase",
      color: "var(--text-subtle)"
    }
  }, l), /*#__PURE__*/React.createElement("div", {
    style: {
      color: "var(--text-body)",
      marginTop: 4
    }
  }, v))), /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: 10,
      letterSpacing: "var(--tracking-wider)",
      textTransform: "uppercase",
      color: "var(--text-subtle)"
    }
  }, "Guests"), /*#__PURE__*/React.createElement("div", {
    style: {
      color: "var(--text-body)",
      marginTop: 4
    }
  }, "2"))), /*#__PURE__*/React.createElement("div", {
    style: {
      display: "flex",
      gap: 8,
      marginTop: 18
    }
  }, /*#__PURE__*/React.createElement(Button, {
    fullWidth: true,
    onClick: () => go("key"),
    iconLeft: /*#__PURE__*/React.createElement(Icon, {
      name: "key-round",
      size: 16
    })
  }, "Open door"), /*#__PURE__*/React.createElement(Button, {
    variant: "secondary",
    onClick: () => go("services")
  }, "Services")))), /*#__PURE__*/React.createElement("div", {
    style: {
      marginTop: 22
    }
  }, /*#__PURE__*/React.createElement("div", {
    className: "hh-eyebrow",
    style: {
      fontSize: 10,
      marginBottom: 12
    }
  }, "Today"), /*#__PURE__*/React.createElement("div", {
    style: {
      display: "flex",
      flexDirection: "column",
      gap: 10
    }
  }, [{
    icon: "utensils",
    t: "Breakfast",
    n: "7:00 – 10:00 AM · Harbour restaurant",
    tag: "Included"
  }, {
    icon: "sparkles",
    t: "Wedding in the Grand Hall",
    n: "6:00 PM · Osei & Lindqvist",
    tag: null
  }, {
    icon: "car",
    t: "Valet collected your car",
    n: "8:12 AM · Level 2, bay 14",
    tag: null
  }].map(r => /*#__PURE__*/React.createElement(Card, {
    key: r.t,
    padding: "14px 16px",
    style: {
      display: "flex",
      alignItems: "center",
      gap: 14
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      color: "var(--teal-700)"
    }
  }, /*#__PURE__*/React.createElement(Icon, {
    name: r.icon,
    size: 20
  })), /*#__PURE__*/React.createElement("div", {
    style: {
      flex: 1
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      fontFamily: "var(--font-sans)",
      fontSize: "var(--text-md)",
      color: "var(--text-heading)"
    }
  }, r.t), /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: "var(--text-sm)",
      color: "var(--text-muted)",
      marginTop: 2
    }
  }, r.n)), r.tag ? /*#__PURE__*/React.createElement(Badge, {
    tone: "teal",
    size: "sm"
  }, r.tag) : /*#__PURE__*/React.createElement(Icon, {
    name: "chevron-right",
    size: 16,
    style: {
      color: "var(--text-subtle)"
    }
  }))))), /*#__PURE__*/React.createElement("div", {
    style: {
      marginTop: 22
    }
  }, /*#__PURE__*/React.createElement("div", {
    className: "hh-eyebrow",
    style: {
      fontSize: 10,
      marginBottom: 12
    }
  }, "Preferences"), /*#__PURE__*/React.createElement(Card, {
    padding: "16px 18px",
    style: {
      display: "flex",
      flexDirection: "column",
      gap: 14
    }
  }, /*#__PURE__*/React.createElement(Switch, {
    label: "Daily housekeeping",
    defaultChecked: true
  }), /*#__PURE__*/React.createElement(Switch, {
    label: "Do not disturb"
  }), /*#__PURE__*/React.createElement(Switch, {
    label: "Late checkout \xB7 $45"
  }))));
}
function KeyScreen({
  go,
  onUnlock,
  unlocked
}) {
  return /*#__PURE__*/React.createElement("div", {
    style: {
      padding: "0 20px 24px"
    }
  }, /*#__PURE__*/React.createElement(AppBar, {
    subtitle: "Room 812",
    title: "Mobile key"
  }), /*#__PURE__*/React.createElement(Card, {
    padding: "28px 22px",
    style: {
      textAlign: "center",
      background: "var(--surface-navy)",
      border: "1px solid transparent",
      color: "var(--text-on-navy)"
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      width: 168,
      height: 200,
      margin: "0 auto",
      borderRadius: "var(--arch-top)",
      border: `1px solid ${unlocked ? "var(--teal-400)" : "rgba(204,156,36,.55)"}`,
      display: "flex",
      alignItems: "center",
      justifyContent: "center",
      transition: "border-color var(--dur-base) var(--ease-standard)"
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      color: unlocked ? "var(--teal-400)" : "var(--gold-500)"
    }
  }, /*#__PURE__*/React.createElement(Icon, {
    name: unlocked ? "door-open" : "key-round",
    size: 56
  }))), /*#__PURE__*/React.createElement("div", {
    style: {
      fontFamily: "var(--font-display)",
      fontSize: 20,
      letterSpacing: ".06em",
      textTransform: "uppercase",
      marginTop: 26
    }
  }, unlocked ? "Door unlocked" : "Hold near the door"), /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: "var(--text-sm)",
      color: "rgba(232,239,246,.7)",
      marginTop: 8
    }
  }, unlocked ? "Relocks in 5 seconds." : "Room 812 · Floor 8, harbour side"), /*#__PURE__*/React.createElement(Button, {
    variant: unlocked ? "inverse" : "gold",
    fullWidth: true,
    size: "lg",
    style: {
      marginTop: 24
    },
    onClick: onUnlock
  }, unlocked ? "Unlocked" : "Unlock")), /*#__PURE__*/React.createElement("div", {
    style: {
      marginTop: 20,
      display: "flex",
      flexDirection: "column",
      gap: 10
    }
  }, [["elevator", "Elevator, floors 1–12"], ["dumbbell", "Fitness room, 24 hours"], ["waves", "Pool deck, 7 AM – 9 PM"]].map(([i, t]) => /*#__PURE__*/React.createElement(Card, {
    key: t,
    padding: "14px 16px",
    style: {
      display: "flex",
      alignItems: "center",
      gap: 14
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      color: "var(--gold-700)"
    }
  }, /*#__PURE__*/React.createElement(Icon, {
    name: i,
    size: 20
  })), /*#__PURE__*/React.createElement("span", {
    style: {
      flex: 1,
      fontFamily: "var(--font-sans)",
      fontSize: "var(--text-md)",
      color: "var(--text-heading)"
    }
  }, t), /*#__PURE__*/React.createElement(Badge, {
    tone: "neutral",
    size: "sm"
  }, "Access")))));
}
function ServicesScreen({
  go,
  onOrder
}) {
  const [tab, setTab] = React.useState("room");
  const items = {
    room: [{
      t: "Harbour club sandwich",
      n: "Fries, pickles · 25 min",
      p: 24
    }, {
      t: "Evening cheese board",
      n: "Three cheeses, quince · 20 min",
      p: 32
    }, {
      t: "Pot of tea",
      n: "Ceylon or mint · 10 min",
      p: 9
    }],
    housekeeping: [{
      t: "Extra towels",
      n: "Delivered within 15 min",
      p: 0
    }, {
      t: "Turn-down service",
      n: "Between 6 and 8 PM",
      p: 0
    }, {
      t: "Laundry pickup",
      n: "Back by 10 AM tomorrow",
      p: 38
    }],
    desk: [{
      t: "Airport transfer",
      n: "Sedan, up to 3 bags",
      p: 68
    }, {
      t: "Dinner reservation",
      n: "We'll call the restaurant",
      p: 0
    }, {
      t: "Late checkout",
      n: "Until 2:00 PM",
      p: 45
    }]
  }[tab];
  return /*#__PURE__*/React.createElement("div", {
    style: {
      padding: "0 20px 24px"
    }
  }, /*#__PURE__*/React.createElement(AppBar, {
    subtitle: "Room 812",
    title: "Services"
  }), /*#__PURE__*/React.createElement(Tabs, {
    variant: "segmented",
    items: [{
      id: "room",
      label: "Room"
    }, {
      id: "housekeeping",
      label: "House"
    }, {
      id: "desk",
      label: "Desk"
    }],
    value: tab,
    onChange: setTab,
    style: {
      marginBottom: 18
    }
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      display: "flex",
      flexDirection: "column",
      gap: 10
    }
  }, items.map(i => /*#__PURE__*/React.createElement(Card, {
    key: i.t,
    padding: "16px",
    style: {
      display: "flex",
      alignItems: "center",
      gap: 14
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      flex: 1
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      fontFamily: "var(--font-serif)",
      fontSize: "var(--serif-sm)",
      color: "var(--text-heading)"
    }
  }, i.t), /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: "var(--text-sm)",
      color: "var(--text-muted)",
      marginTop: 3
    }
  }, i.n)), /*#__PURE__*/React.createElement("div", {
    style: {
      textAlign: "right"
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      fontFamily: "var(--font-sans)",
      fontSize: "var(--text-md)",
      color: i.p ? "var(--text-heading)" : "var(--teal-700)"
    }
  }, i.p ? `$${i.p}` : "No charge"), /*#__PURE__*/React.createElement(Button, {
    size: "sm",
    variant: "secondary",
    style: {
      marginTop: 8
    },
    onClick: () => onOrder(i.t)
  }, "Add"))))), /*#__PURE__*/React.createElement(Card, {
    padding: "18px",
    style: {
      marginTop: 18,
      display: "flex",
      gap: 14,
      alignItems: "center",
      background: "var(--surface-gold-tint)",
      border: "1px solid var(--gold-300)"
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      color: "var(--gold-800)"
    }
  }, /*#__PURE__*/React.createElement(Icon, {
    name: "message-square",
    size: 20
  })), /*#__PURE__*/React.createElement("div", {
    style: {
      flex: 1
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      fontFamily: "var(--font-sans)",
      fontSize: "var(--text-md)",
      color: "var(--navy-800)"
    }
  }, "Message the front desk"), /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: "var(--text-sm)",
      color: "var(--gold-900)",
      marginTop: 2
    }
  }, "Replies in a few minutes, 24 hours")), /*#__PURE__*/React.createElement(Icon, {
    name: "chevron-right",
    size: 16,
    style: {
      color: "var(--gold-800)"
    }
  })));
}
Object.assign(window, {
  StayScreen,
  KeyScreen,
  ServicesScreen
});
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/guest-app/Screens.jsx", error: String((e && e.message) || e) }); }

// ui_kits/website/Checkout.jsx
try { (() => {
const {
  Button,
  Card,
  CardTitle,
  CardMeta,
  Badge,
  Input,
  Select,
  Checkbox,
  RadioGroup,
  Dialog,
  Toast,
  Rating
} = window.HotelHallDesignSystem_6ae9d5;
function Checkout({
  room,
  go,
  onConfirmed
}) {
  const [rate, setRate] = React.useState("flex");
  const [confirming, setConfirming] = React.useState(false);
  const nights = 3;
  const base = room.price * nights;
  const extras = rate === "saver" ? -32 : 0;
  const tax = Math.round((base + extras) * 0.09);
  const total = base + extras + tax;
  return /*#__PURE__*/React.createElement("div", {
    style: {
      position: "relative",
      maxWidth: "var(--container-max)",
      margin: "0 auto",
      padding: "var(--space-9) var(--gutter) 0"
    }
  }, /*#__PURE__*/React.createElement("button", {
    onClick: () => go("rooms"),
    style: {
      border: 0,
      background: "none",
      padding: 0,
      cursor: "pointer",
      display: "flex",
      alignItems: "center",
      gap: 6,
      fontFamily: "var(--font-sans)",
      fontSize: "var(--text-xs)",
      letterSpacing: "var(--tracking-wider)",
      textTransform: "uppercase",
      color: "var(--text-muted)"
    }
  }, /*#__PURE__*/React.createElement(Icon, {
    name: "chevron-left",
    size: 14
  }), " Back to rooms"), /*#__PURE__*/React.createElement("h1", {
    style: {
      fontSize: "var(--display-md)",
      margin: "18px 0 32px"
    }
  }, "Confirm your stay"), /*#__PURE__*/React.createElement("div", {
    style: {
      display: "grid",
      gridTemplateColumns: "1fr 380px",
      gap: 40,
      alignItems: "start"
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      display: "flex",
      flexDirection: "column",
      gap: 20
    }
  }, /*#__PURE__*/React.createElement(Card, {
    padding: "var(--card-pad-lg)"
  }, /*#__PURE__*/React.createElement("div", {
    className: "hh-eyebrow"
  }, "1 \xB7 Rate"), /*#__PURE__*/React.createElement("div", {
    style: {
      marginTop: 18
    }
  }, /*#__PURE__*/React.createElement(RadioGroup, {
    value: rate,
    onChange: setRate,
    options: [{
      value: "flex",
      label: `Flexible — $${room.price} / night`,
      description: "Free cancellation until Aug 12, pay at check-in"
    }, {
      value: "saver",
      label: `Advance saver — $${room.price - 11} / night`,
      description: "Non-refundable, charged today · save $32"
    }]
  }))), /*#__PURE__*/React.createElement(Card, {
    padding: "var(--card-pad-lg)"
  }, /*#__PURE__*/React.createElement("div", {
    className: "hh-eyebrow"
  }, "2 \xB7 Guest details"), /*#__PURE__*/React.createElement("div", {
    style: {
      display: "grid",
      gridTemplateColumns: "1fr 1fr",
      gap: 14,
      marginTop: 18
    }
  }, /*#__PURE__*/React.createElement(Input, {
    label: "First name",
    defaultValue: "Amara"
  }), /*#__PURE__*/React.createElement(Input, {
    label: "Last name",
    defaultValue: "Osei"
  }), /*#__PURE__*/React.createElement(Input, {
    label: "Email",
    defaultValue: "amara@example.com",
    hint: "Your confirmation goes here."
  }), /*#__PURE__*/React.createElement(Input, {
    label: "Phone",
    defaultValue: "+1 555 0134"
  }), /*#__PURE__*/React.createElement(Select, {
    label: "Arrival time",
    options: ["3:00 – 6:00 PM", "6:00 – 9:00 PM", "After 9:00 PM"]
  }), /*#__PURE__*/React.createElement(Select, {
    label: "Bed",
    options: ["King", "Twin"]
  })), /*#__PURE__*/React.createElement("div", {
    style: {
      marginTop: 20,
      display: "flex",
      flexDirection: "column",
      gap: 12,
      borderTop: "1px solid var(--border-subtle)",
      paddingTop: 20
    }
  }, /*#__PURE__*/React.createElement(Checkbox, {
    label: "Add breakfast",
    description: "$28 per guest, served 7\u201310 AM",
    defaultChecked: true
  }), /*#__PURE__*/React.createElement(Checkbox, {
    label: "Valet parking",
    description: "$32 per night"
  }))), /*#__PURE__*/React.createElement(Card, {
    padding: "var(--card-pad-lg)"
  }, /*#__PURE__*/React.createElement("div", {
    className: "hh-eyebrow"
  }, "3 \xB7 Payment"), /*#__PURE__*/React.createElement("div", {
    style: {
      display: "grid",
      gridTemplateColumns: "2fr 1fr 1fr",
      gap: 14,
      marginTop: 18
    }
  }, /*#__PURE__*/React.createElement(Input, {
    label: "Card number",
    defaultValue: "4242 4242 4242 4242",
    iconLeft: /*#__PURE__*/React.createElement(Icon, {
      name: "credit-card",
      size: 16
    })
  }), /*#__PURE__*/React.createElement(Input, {
    label: "Expiry",
    defaultValue: "09 / 29"
  }), /*#__PURE__*/React.createElement(Input, {
    label: "CVC",
    defaultValue: "123"
  })), /*#__PURE__*/React.createElement("p", {
    style: {
      fontSize: "var(--text-xs)",
      color: "var(--text-subtle)",
      marginTop: 14,
      marginBottom: 0
    }
  }, "We hold the room until 6:00 PM on the day of arrival. Nothing is charged until check-in on the flexible rate."))), /*#__PURE__*/React.createElement(Card, {
    padding: "0",
    style: {
      position: "sticky",
      top: 96
    }
  }, /*#__PURE__*/React.createElement(Photo, {
    label: "Room 3:2",
    ratio: "3 / 2",
    radius: "0"
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      padding: "var(--card-pad-lg)"
    }
  }, /*#__PURE__*/React.createElement(CardTitle, null, room.name), /*#__PURE__*/React.createElement(CardMeta, {
    style: {
      marginTop: 6
    }
  }, room.meta), /*#__PURE__*/React.createElement(Rating, {
    value: room.rating,
    count: room.reviews,
    style: {
      marginTop: 12
    }
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      borderTop: "1px solid var(--border-subtle)",
      margin: "20px 0",
      paddingTop: 20,
      display: "flex",
      flexDirection: "column",
      gap: 10,
      fontFamily: "var(--font-sans)",
      fontSize: "var(--text-sm)"
    }
  }, [["Aug 12 – Aug 15", `${nights} nights`], [`$${room.price} × ${nights} nights`, `$${base}`], ...(extras ? [["Advance saver", `−$${-extras}`]] : []), ["Taxes & fees", `$${tax}`]].map(([l, v]) => /*#__PURE__*/React.createElement("div", {
    key: l,
    style: {
      display: "flex",
      justifyContent: "space-between",
      color: "var(--text-muted)"
    }
  }, /*#__PURE__*/React.createElement("span", null, l), /*#__PURE__*/React.createElement("span", {
    style: {
      color: "var(--text-body)"
    }
  }, v)))), /*#__PURE__*/React.createElement("div", {
    style: {
      display: "flex",
      justifyContent: "space-between",
      alignItems: "baseline",
      borderTop: "1px solid var(--border-subtle)",
      paddingTop: 16
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      fontFamily: "var(--font-sans)",
      fontSize: "var(--text-xs)",
      letterSpacing: "var(--tracking-wider)",
      textTransform: "uppercase",
      color: "var(--text-muted)"
    }
  }, "Total"), /*#__PURE__*/React.createElement("span", {
    style: {
      fontFamily: "var(--font-sans)",
      fontSize: "var(--text-2xl)",
      color: "var(--text-heading)"
    }
  }, "$", total)), /*#__PURE__*/React.createElement(Button, {
    fullWidth: true,
    size: "lg",
    style: {
      marginTop: 18
    },
    onClick: () => setConfirming(true)
  }, "Reserve"), /*#__PURE__*/React.createElement("div", {
    style: {
      display: "flex",
      alignItems: "center",
      gap: 6,
      marginTop: 12,
      fontSize: "var(--text-xs)",
      color: "var(--success-700)"
    }
  }, /*#__PURE__*/React.createElement(Icon, {
    name: "check",
    size: 14
  }), " ", rate === "flex" ? "Free cancellation until Aug 12" : "Non-refundable rate")))), /*#__PURE__*/React.createElement(Dialog, {
    open: confirming,
    eyebrow: "Almost there",
    title: "Confirm your stay",
    onClose: () => setConfirming(false),
    footer: /*#__PURE__*/React.createElement(React.Fragment, null, /*#__PURE__*/React.createElement(Button, {
      variant: "ghost",
      onClick: () => setConfirming(false)
    }, "Back"), /*#__PURE__*/React.createElement(Button, {
      onClick: () => {
        setConfirming(false);
        onConfirmed();
      }
    }, "Reserve"))
  }, room.name, ", Aug 12\u201315 for 2 guests. $", total, " total", rate === "flex" ? ", charged at check-in." : ", charged today."));
}
Object.assign(window, {
  Checkout
});
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/website/Checkout.jsx", error: String((e && e.message) || e) }); }

// ui_kits/website/Home.jsx
try { (() => {
const {
  Button,
  Card,
  CardTitle,
  CardMeta,
  Badge,
  Tag,
  Rating,
  DateField,
  Select
} = window.HotelHallDesignSystem_6ae9d5;
function SearchBar({
  onSearch,
  floating = false
}) {
  return /*#__PURE__*/React.createElement("div", {
    style: {
      display: "flex",
      alignItems: "flex-end",
      gap: 12,
      background: floating ? "var(--surface-glass)" : "var(--surface-card)",
      backdropFilter: floating ? "var(--blur-glass)" : "none",
      border: "1px solid var(--border-subtle)",
      borderRadius: "var(--radius-lg)",
      boxShadow: "var(--shadow-md)",
      padding: 16
    }
  }, /*#__PURE__*/React.createElement(DateField, {
    checkIn: "Aug 12",
    checkOut: "Aug 15",
    nights: 3,
    style: {
      flex: 1.6
    }
  }), /*#__PURE__*/React.createElement(Select, {
    label: "Guests",
    options: ["2 guests", "1 guest", "3 guests", "4 guests"],
    size: "lg",
    style: {
      height: "calc(var(--control-h-md) + 8px)"
    }
  }), /*#__PURE__*/React.createElement(Select, {
    label: "Occasion",
    options: ["A stay", "A celebration", "A meeting"],
    size: "lg",
    style: {
      height: "calc(var(--control-h-md) + 8px)"
    }
  }), /*#__PURE__*/React.createElement(Button, {
    size: "lg",
    onClick: onSearch,
    style: {
      height: "calc(var(--control-h-md) + 8px)"
    }
  }, "Check availability"));
}
function Hero({
  go
}) {
  return /*#__PURE__*/React.createElement("div", {
    style: {
      position: "relative",
      marginTop: -76
    }
  }, /*#__PURE__*/React.createElement(Photo, {
    tone: "deep",
    ratio: "auto",
    radius: "0",
    label: "Full-bleed hero photography",
    style: {
      height: 620,
      alignItems: "flex-end",
      justifyContent: "flex-start"
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      position: "absolute",
      inset: 0,
      background: "var(--scrim-bottom)"
    }
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      position: "absolute",
      inset: 0,
      background: "var(--scrim-top)"
    }
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      position: "relative",
      maxWidth: "var(--container-max)",
      width: "100%",
      margin: "0 auto",
      padding: "0 var(--gutter) 74px"
    }
  }, /*#__PURE__*/React.createElement("div", {
    className: "hh-eyebrow",
    style: {
      color: "var(--gold-400)"
    }
  }, "Harbour Road \xB7 Est. 1974"), /*#__PURE__*/React.createElement("h1", {
    style: {
      color: "#fff",
      fontSize: "var(--display-xl)",
      margin: "18px 0 0",
      maxWidth: 760
    }
  }, "Stay comfortable", /*#__PURE__*/React.createElement("br", null), "Celebrate memorable"), /*#__PURE__*/React.createElement("p", {
    style: {
      fontFamily: "var(--font-serif)",
      fontSize: "var(--serif-md)",
      color: "rgba(255,255,255,.86)",
      maxWidth: 520,
      marginTop: 18
    }
  }, "Ninety-four rooms above the harbour, and a hall that seats 180 for the evening after."))), /*#__PURE__*/React.createElement("div", {
    style: {
      maxWidth: "var(--container-max)",
      margin: "-44px auto 0",
      padding: "0 var(--gutter)",
      position: "relative",
      zIndex: 5
    }
  }, /*#__PURE__*/React.createElement(SearchBar, {
    onSearch: () => go("rooms"),
    floating: true
  })));
}
function RoomCard({
  room,
  go
}) {
  return /*#__PURE__*/React.createElement(Card, {
    image: "",
    interactive: true,
    onClick: () => go("rooms")
  }, /*#__PURE__*/React.createElement(Photo, {
    label: "Room 4:3",
    ratio: "4 / 3",
    radius: "0",
    style: {
      margin: "-20px -20px 18px"
    }
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      display: "flex",
      justifyContent: "space-between",
      alignItems: "flex-start",
      gap: 10
    }
  }, /*#__PURE__*/React.createElement(CardTitle, null, room.name), /*#__PURE__*/React.createElement(Rating, {
    value: room.rating,
    label: false,
    size: 14
  })), /*#__PURE__*/React.createElement(CardMeta, {
    style: {
      marginTop: 6
    }
  }, room.meta), /*#__PURE__*/React.createElement("div", {
    style: {
      display: "flex",
      gap: 6,
      marginTop: 14,
      flexWrap: "wrap"
    }
  }, room.tags.map(t => /*#__PURE__*/React.createElement(Badge, {
    key: t,
    tone: "neutral",
    size: "sm"
  }, t))), /*#__PURE__*/React.createElement("div", {
    style: {
      display: "flex",
      justifyContent: "space-between",
      alignItems: "baseline",
      marginTop: 18,
      paddingTop: 16,
      borderTop: "1px solid var(--border-subtle)"
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      fontFamily: "var(--font-sans)",
      fontSize: "var(--text-xl)",
      color: "var(--text-heading)"
    }
  }, "$", room.price), /*#__PURE__*/React.createElement("span", {
    style: {
      fontSize: "var(--text-xs)",
      color: "var(--text-muted)"
    }
  }, "per night")));
}
function Home({
  go
}) {
  return /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement(Hero, {
    go: go
  }), /*#__PURE__*/React.createElement(Section, {
    eyebrow: "Book \u2022 Stay",
    title: "Rooms & suites",
    intro: "Every rate includes Wi-Fi, the harbour breakfast, and a 6 PM hold on your arrival."
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      display: "grid",
      gridTemplateColumns: "repeat(4, 1fr)",
      gap: 20
    }
  }, ROOMS.map(r => /*#__PURE__*/React.createElement(RoomCard, {
    key: r.id,
    room: r,
    go: go
  }))), /*#__PURE__*/React.createElement("div", {
    style: {
      marginTop: 32
    }
  }, /*#__PURE__*/React.createElement(Button, {
    variant: "secondary",
    onClick: () => go("rooms")
  }, "See all 94 rooms"))), /*#__PURE__*/React.createElement("section", {
    style: {
      background: "var(--surface-navy)",
      color: "var(--text-on-navy)",
      padding: "var(--section-y) 0"
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      maxWidth: "var(--container-max)",
      margin: "0 auto",
      padding: "0 var(--gutter)",
      display: "grid",
      gridTemplateColumns: "1fr 1.05fr",
      gap: 64,
      alignItems: "center"
    }
  }, /*#__PURE__*/React.createElement(Photo, {
    tone: "deep",
    ratio: "3 / 4",
    radius: "var(--arch-top)",
    label: "Venue archway 3:4",
    style: {
      border: "1px solid rgba(204,156,36,.4)"
    }
  }), /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement("div", {
    className: "hh-eyebrow",
    style: {
      color: "var(--gold-400)"
    }
  }, "Celebrate"), /*#__PURE__*/React.createElement("h2", {
    style: {
      color: "#fff",
      marginTop: 16
    }
  }, "The Grand Hall"), /*#__PURE__*/React.createElement("p", {
    style: {
      fontFamily: "var(--font-serif)",
      fontSize: "var(--serif-md)",
      color: "rgba(232,239,246,.8)",
      maxWidth: 460
    }
  }, "A chandeliered hall under the original 1974 arch. Seats 180 for dinner, 240 standing, with a dance floor and a service kitchen of its own."), /*#__PURE__*/React.createElement("div", {
    style: {
      display: "grid",
      gridTemplateColumns: "repeat(3,1fr)",
      gap: 24,
      margin: "32px 0",
      maxWidth: 460
    }
  }, [["180", "seated"], ["240", "standing"], ["12", "hours exclusive"]].map(([n, l]) => /*#__PURE__*/React.createElement("div", {
    key: l
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      fontFamily: "var(--font-display)",
      fontSize: 34,
      color: "var(--gold-500)"
    }
  }, n), /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: "var(--text-xs)",
      letterSpacing: "var(--tracking-wider)",
      textTransform: "uppercase",
      color: "rgba(232,239,246,.6)",
      marginTop: 4
    }
  }, l)))), /*#__PURE__*/React.createElement("div", {
    style: {
      display: "flex",
      gap: 10
    }
  }, /*#__PURE__*/React.createElement(Button, {
    variant: "gold",
    onClick: () => go("venue")
  }, "Request a quote"), /*#__PURE__*/React.createElement(Button, {
    variant: "inverse",
    onClick: () => go("venue")
  }, "See the Grand Hall"))))), /*#__PURE__*/React.createElement(Section, {
    eyebrow: "In the hotel",
    title: "Amenities"
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      display: "grid",
      gridTemplateColumns: "repeat(4,1fr)",
      gap: 20
    }
  }, AMENITIES.map(a => /*#__PURE__*/React.createElement("div", {
    key: a.label,
    style: {
      display: "flex",
      gap: 14
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      color: "var(--teal-700)",
      marginTop: 2
    }
  }, /*#__PURE__*/React.createElement(Icon, {
    name: a.icon,
    size: 22
  })), /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement("div", {
    style: {
      fontFamily: "var(--font-sans)",
      fontSize: "var(--text-md)",
      color: "var(--text-heading)"
    }
  }, a.label), /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: "var(--text-sm)",
      color: "var(--text-muted)",
      marginTop: 4
    }
  }, a.note)))))), /*#__PURE__*/React.createElement("section", {
    style: {
      background: "var(--surface-sunken)",
      padding: "var(--section-y-tight) 0"
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      maxWidth: "var(--container-narrow)",
      margin: "0 auto",
      padding: "0 var(--gutter)",
      textAlign: "center"
    }
  }, /*#__PURE__*/React.createElement("div", {
    className: "hh-rule-gold"
  }, /*#__PURE__*/React.createElement("span", {
    className: "hh-eyebrow"
  }, "Guest reviews")), /*#__PURE__*/React.createElement("p", {
    style: {
      fontFamily: "var(--font-serif)",
      fontSize: "var(--serif-lg)",
      fontStyle: "italic",
      color: "var(--text-heading)",
      margin: "26px 0 18px"
    }
  }, "\u201CWe held the wedding in the hall and put forty guests upstairs. Both halves ran without a single question from us.\u201D"), /*#__PURE__*/React.createElement(Rating, {
    value: 4.7,
    count: 780,
    style: {
      justifyContent: "center"
    }
  }))));
}
Object.assign(window, {
  Home,
  SearchBar,
  RoomCard,
  Hero
});
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/website/Home.jsx", error: String((e && e.message) || e) }); }

// ui_kits/website/Rooms.jsx
try { (() => {
const {
  Button,
  Card,
  CardTitle,
  CardMeta,
  Badge,
  Tag,
  Rating,
  Tabs,
  Checkbox,
  RadioGroup,
  Tooltip,
  IconButton
} = window.HotelHallDesignSystem_6ae9d5;
function Rooms({
  go,
  onReserve
}) {
  const [filters, setFilters] = React.useState(["Harbour view"]);
  const [sort, setSort] = React.useState("price");
  const toggle = t => setFilters(f => f.includes(t) ? f.filter(x => x !== t) : [...f, t]);
  const chips = ["Harbour view", "Balcony", "Connecting", "Quiet wing", "Breakfast"];
  return /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement("div", {
    style: {
      borderBottom: "1px solid var(--border-subtle)",
      background: "var(--surface-card)"
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      maxWidth: "var(--container-max)",
      margin: "0 auto",
      padding: "var(--space-9) var(--gutter) var(--space-7)"
    }
  }, /*#__PURE__*/React.createElement("div", {
    className: "hh-eyebrow"
  }, "Book \u2022 Stay"), /*#__PURE__*/React.createElement("h1", {
    style: {
      fontSize: "var(--display-lg)",
      margin: "14px 0 6px"
    }
  }, "Rooms & suites"), /*#__PURE__*/React.createElement("p", {
    style: {
      color: "var(--text-muted)",
      marginBottom: 24
    }
  }, "94 rooms \xB7 Aug 12\u201315 \xB7 2 guests"), /*#__PURE__*/React.createElement(SearchBar, {
    onSearch: () => {}
  }))), /*#__PURE__*/React.createElement("div", {
    style: {
      maxWidth: "var(--container-max)",
      margin: "0 auto",
      padding: "var(--space-9) var(--gutter) 0",
      display: "grid",
      gridTemplateColumns: "236px 1fr",
      gap: 40
    }
  }, /*#__PURE__*/React.createElement("aside", null, /*#__PURE__*/React.createElement("div", {
    style: {
      fontFamily: "var(--font-sans)",
      fontSize: "var(--text-xs)",
      letterSpacing: "var(--tracking-wider)",
      textTransform: "uppercase",
      color: "var(--text-muted)",
      marginBottom: 14
    }
  }, "Filter"), /*#__PURE__*/React.createElement("div", {
    style: {
      display: "flex",
      flexWrap: "wrap",
      gap: 6,
      marginBottom: 26
    }
  }, chips.map(c => /*#__PURE__*/React.createElement(Tag, {
    key: c,
    selected: filters.includes(c),
    onClick: () => toggle(c)
  }, c))), /*#__PURE__*/React.createElement("div", {
    style: {
      borderTop: "1px solid var(--border-subtle)",
      paddingTop: 22
    }
  }, /*#__PURE__*/React.createElement(RadioGroup, {
    label: "Rate",
    value: sort,
    onChange: setSort,
    options: [{
      value: "price",
      label: "Flexible",
      description: "Free cancellation until Aug 12"
    }, {
      value: "saver",
      label: "Advance saver",
      description: "Non-refundable · save $32"
    }]
  })), /*#__PURE__*/React.createElement("div", {
    style: {
      borderTop: "1px solid var(--border-subtle)",
      marginTop: 22,
      paddingTop: 22,
      display: "flex",
      flexDirection: "column",
      gap: 12
    }
  }, /*#__PURE__*/React.createElement(Checkbox, {
    label: "Add breakfast",
    description: "$28 per guest",
    defaultChecked: true
  }), /*#__PURE__*/React.createElement(Checkbox, {
    label: "Valet parking",
    description: "$32 per night"
  }), /*#__PURE__*/React.createElement(Checkbox, {
    label: "Accessible room"
  }))), /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement("div", {
    style: {
      display: "flex",
      justifyContent: "space-between",
      alignItems: "center",
      marginBottom: 20
    }
  }, /*#__PURE__*/React.createElement(Tabs, {
    items: [{
      id: "all",
      label: "All rooms",
      count: 4
    }, {
      id: "suites",
      label: "Suites"
    }, {
      id: "family",
      label: "Family"
    }]
  }), /*#__PURE__*/React.createElement("span", {
    style: {
      fontSize: "var(--text-sm)",
      color: "var(--text-muted)"
    }
  }, "Sorted by price")), /*#__PURE__*/React.createElement("div", {
    style: {
      display: "flex",
      flexDirection: "column",
      gap: 16
    }
  }, ROOMS.map((r, i) => /*#__PURE__*/React.createElement(Card, {
    key: r.id,
    padding: "0",
    interactive: true,
    style: {
      display: "grid",
      gridTemplateColumns: "300px 1fr"
    }
  }, /*#__PURE__*/React.createElement(Photo, {
    label: "Room 3:2",
    ratio: "3 / 2",
    radius: "0"
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      padding: "var(--card-pad-lg)",
      display: "flex",
      gap: 28
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      flex: 1
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      display: "flex",
      alignItems: "center",
      gap: 10
    }
  }, /*#__PURE__*/React.createElement(CardTitle, {
    style: {
      fontSize: "var(--serif-lg)"
    }
  }, r.name), i === 0 ? /*#__PURE__*/React.createElement(Badge, {
    tone: "gold",
    size: "sm"
  }, "2 left") : null), /*#__PURE__*/React.createElement(CardMeta, {
    style: {
      marginTop: 8
    }
  }, r.meta), /*#__PURE__*/React.createElement("p", {
    style: {
      fontFamily: "var(--font-serif)",
      fontSize: "var(--serif-sm)",
      color: "var(--text-body)",
      margin: "12px 0 0",
      maxWidth: 420
    }
  }, r.note), /*#__PURE__*/React.createElement("div", {
    style: {
      display: "flex",
      gap: 6,
      marginTop: 16,
      flexWrap: "wrap"
    }
  }, r.tags.map(t => /*#__PURE__*/React.createElement(Badge, {
    key: t,
    tone: "neutral",
    size: "sm"
  }, t)), /*#__PURE__*/React.createElement(Badge, {
    tone: "teal",
    size: "sm"
  }, "Breakfast included")), /*#__PURE__*/React.createElement(Rating, {
    value: r.rating,
    count: r.reviews,
    style: {
      marginTop: 16
    }
  })), /*#__PURE__*/React.createElement("div", {
    style: {
      width: 170,
      borderLeft: "1px solid var(--border-subtle)",
      paddingLeft: 24,
      display: "flex",
      flexDirection: "column",
      justifyContent: "space-between"
    }
  }, /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement("div", {
    style: {
      fontFamily: "var(--font-sans)",
      fontSize: "var(--text-2xl)",
      color: "var(--text-heading)"
    }
  }, "$", r.price), /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: "var(--text-xs)",
      color: "var(--text-muted)",
      marginTop: 2
    }
  }, "per night \xB7 $", r.price * 3, " total"), /*#__PURE__*/React.createElement("div", {
    style: {
      display: "flex",
      alignItems: "center",
      gap: 6,
      marginTop: 12,
      fontSize: "var(--text-xs)",
      color: "var(--success-700)"
    }
  }, /*#__PURE__*/React.createElement(Icon, {
    name: "check",
    size: 14
  }), " Free cancellation")), /*#__PURE__*/React.createElement("div", {
    style: {
      display: "flex",
      flexDirection: "column",
      gap: 8
    }
  }, /*#__PURE__*/React.createElement(Button, {
    fullWidth: true,
    onClick: e => {
      e.stopPropagation();
      onReserve(r);
    }
  }, "Reserve"), /*#__PURE__*/React.createElement("div", {
    style: {
      display: "flex",
      gap: 8
    }
  }, /*#__PURE__*/React.createElement(Button, {
    variant: "ghost",
    size: "sm",
    style: {
      flex: 1
    }
  }, "Details"), /*#__PURE__*/React.createElement(Tooltip, {
    label: "Save for later"
  }, /*#__PURE__*/React.createElement(IconButton, {
    icon: /*#__PURE__*/React.createElement(Icon, {
      name: "heart",
      size: 16
    }),
    label: "Save",
    size: "sm",
    variant: "outline"
  }))))))))))));
}
Object.assign(window, {
  Rooms
});
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/website/Rooms.jsx", error: String((e && e.message) || e) }); }

// ui_kits/website/Shell.jsx
try { (() => {
const {
  IconButton,
  Button,
  Badge,
  Rating
} = window.HotelHallDesignSystem_6ae9d5;
function Icon({
  name,
  size = 18,
  style
}) {
  const r = React.useRef(null);
  React.useEffect(() => {
    if (r.current && window.lucide) {
      r.current.innerHTML = "";
      const el = document.createElement("i");
      el.setAttribute("data-lucide", name);
      r.current.appendChild(el);
      window.lucide.createIcons({
        attrs: {
          width: size,
          height: size,
          "stroke-width": 1.5
        },
        nameAttr: "data-lucide"
      });
    }
  }, [name, size]);
  return /*#__PURE__*/React.createElement("span", {
    ref: r,
    style: {
      display: "inline-flex",
      lineHeight: 0,
      ...style
    }
  });
}

/* Flat placeholder — no photography was supplied with the brand assets. */
function Photo({
  label = "Photography",
  ratio = "16 / 9",
  tone = "sand",
  radius = "var(--radius-image)",
  children,
  style
}) {
  const bg = {
    sand: "var(--sand-100)",
    navy: "var(--navy-100)",
    teal: "var(--teal-100)",
    deep: "var(--navy-700)"
  }[tone];
  return /*#__PURE__*/React.createElement("div", {
    style: {
      position: "relative",
      aspectRatio: ratio,
      background: bg,
      borderRadius: radius,
      overflow: "hidden",
      display: "flex",
      alignItems: "center",
      justifyContent: "center",
      ...style
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      fontFamily: "var(--font-sans)",
      fontSize: 11,
      letterSpacing: ".18em",
      textTransform: "uppercase",
      color: tone === "deep" ? "rgba(255,255,255,.35)" : "var(--text-subtle)"
    }
  }, label), children);
}
const NAV = [{
  id: "home",
  label: "Stay"
}, {
  id: "rooms",
  label: "Rooms"
}, {
  id: "venue",
  label: "Celebrate"
}];
function Header({
  route,
  go,
  overHero = false
}) {
  const dark = overHero;
  return /*#__PURE__*/React.createElement("header", {
    style: {
      position: "sticky",
      top: 0,
      zIndex: 30,
      background: dark ? "transparent" : "rgba(251,250,247,.94)",
      backdropFilter: dark ? "none" : "var(--blur-glass)",
      borderBottom: dark ? "1px solid transparent" : "1px solid var(--border-subtle)",
      boxShadow: dark ? "none" : "var(--shadow-xs)",
      transition: "var(--transition-control)"
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      maxWidth: "var(--container-max)",
      margin: "0 auto",
      padding: "0 var(--gutter)",
      height: 76,
      display: "flex",
      alignItems: "center",
      gap: 40
    }
  }, /*#__PURE__*/React.createElement("a", {
    href: "#",
    onClick: e => {
      e.preventDefault();
      go("home");
    },
    style: {
      border: 0,
      display: "flex",
      flexDirection: "column",
      lineHeight: 1
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      fontFamily: "var(--font-display)",
      fontSize: 22,
      letterSpacing: ".08em",
      textTransform: "uppercase",
      color: dark ? "#fff" : "var(--navy-700)"
    }
  }, "Hotel ", /*#__PURE__*/React.createElement("span", {
    style: {
      color: dark ? "var(--teal-400)" : "var(--teal-700)"
    }
  }, "Hall")), /*#__PURE__*/React.createElement("span", {
    style: {
      fontFamily: "var(--font-sans)",
      fontSize: 8,
      letterSpacing: ".24em",
      textTransform: "uppercase",
      color: dark ? "var(--gold-400)" : "var(--gold-700)",
      marginTop: 5
    }
  }, "Book \u2022 Stay \u2022 Celebrate")), /*#__PURE__*/React.createElement("nav", {
    style: {
      display: "flex",
      gap: 28,
      flex: 1
    }
  }, NAV.map(n => /*#__PURE__*/React.createElement("a", {
    key: n.id,
    href: "#",
    onClick: e => {
      e.preventDefault();
      go(n.id);
    },
    style: {
      border: 0,
      fontFamily: "var(--font-sans)",
      fontSize: "var(--text-xs)",
      letterSpacing: "var(--tracking-wider)",
      textTransform: "uppercase",
      color: dark ? route === n.id ? "#fff" : "rgba(255,255,255,.75)" : route === n.id ? "var(--text-heading)" : "var(--text-muted)",
      paddingBottom: 3,
      borderBottom: route === n.id ? `1px solid ${dark ? "var(--gold-400)" : "var(--gold-600)"}` : "1px solid transparent"
    }
  }, n.label))), /*#__PURE__*/React.createElement("div", {
    style: {
      display: "flex",
      alignItems: "center",
      gap: 10
    }
  }, /*#__PURE__*/React.createElement(IconButton, {
    icon: /*#__PURE__*/React.createElement(Icon, {
      name: "phone"
    }),
    label: "Call the hotel",
    variant: dark ? "glass" : "ghost"
  }), /*#__PURE__*/React.createElement(Button, {
    variant: dark ? "inverse" : "primary",
    onClick: () => go("rooms")
  }, "Check availability"))));
}
function Footer({
  go
}) {
  const col = (title, items) => /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement("div", {
    style: {
      fontFamily: "var(--font-sans)",
      fontSize: "var(--text-2xs)",
      letterSpacing: "var(--tracking-widest)",
      textTransform: "uppercase",
      color: "var(--gold-500)",
      marginBottom: 16
    }
  }, title), /*#__PURE__*/React.createElement("div", {
    style: {
      display: "flex",
      flexDirection: "column",
      gap: 10
    }
  }, items.map(i => /*#__PURE__*/React.createElement("span", {
    key: i,
    style: {
      fontSize: "var(--text-sm)",
      color: "rgba(232,239,246,.72)"
    }
  }, i))));
  return /*#__PURE__*/React.createElement("footer", {
    style: {
      background: "var(--surface-navy-deep)",
      color: "var(--text-on-navy)",
      marginTop: "var(--space-13)"
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      maxWidth: "var(--container-max)",
      margin: "0 auto",
      padding: "var(--space-12) var(--gutter) var(--space-9)",
      display: "grid",
      gridTemplateColumns: "1.4fr 1fr 1fr 1fr",
      gap: 40
    }
  }, /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement("div", {
    style: {
      fontFamily: "var(--font-display)",
      fontSize: 24,
      letterSpacing: ".08em",
      textTransform: "uppercase"
    }
  }, "Hotel ", /*#__PURE__*/React.createElement("span", {
    style: {
      color: "var(--teal-400)"
    }
  }, "Hall")), /*#__PURE__*/React.createElement("div", {
    style: {
      fontFamily: "var(--font-serif)",
      fontSize: 18,
      color: "rgba(232,239,246,.72)",
      marginTop: 12,
      maxWidth: 280
    }
  }, "Stay comfortable, celebrate memorable."), /*#__PURE__*/React.createElement("div", {
    style: {
      display: "flex",
      gap: 8,
      marginTop: 22
    }
  }, ["instagram", "facebook", "linkedin"].map(s => /*#__PURE__*/React.createElement("span", {
    key: s,
    style: {
      width: 34,
      height: 34,
      border: "1px solid rgba(255,255,255,.18)",
      borderRadius: "var(--radius-sm)",
      display: "flex",
      alignItems: "center",
      justifyContent: "center",
      color: "rgba(232,239,246,.8)"
    }
  }, /*#__PURE__*/React.createElement(Icon, {
    name: s,
    size: 16
  }))))), col("Stay", ["Rooms & suites", "Offers", "Amenities", "Dining"]), col("Celebrate", ["The Grand Hall", "Weddings", "Corporate events", "Request a quote"]), col("Visit", ["42 Harbour Road", "Front desk +1 555 0134", "stay@hotelhall.com", "Directions"])), /*#__PURE__*/React.createElement("div", {
    style: {
      borderTop: "1px solid rgba(255,255,255,.12)"
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      maxWidth: "var(--container-max)",
      margin: "0 auto",
      padding: "20px var(--gutter)",
      display: "flex",
      justifyContent: "space-between",
      fontSize: "var(--text-xs)",
      color: "rgba(232,239,246,.5)"
    }
  }, /*#__PURE__*/React.createElement("span", null, "\xA9 2026 Hotel Hall"), /*#__PURE__*/React.createElement("span", {
    style: {
      display: "flex",
      gap: 22
    }
  }, /*#__PURE__*/React.createElement("span", null, "Privacy"), /*#__PURE__*/React.createElement("span", null, "Accessibility"), /*#__PURE__*/React.createElement("span", null, "Terms")))));
}
function Section({
  eyebrow,
  title,
  intro,
  children,
  background = "transparent",
  narrow = false,
  style
}) {
  return /*#__PURE__*/React.createElement("section", {
    style: {
      background,
      padding: "var(--section-y) 0",
      ...style
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      maxWidth: narrow ? "var(--container-narrow)" : "var(--container-max)",
      margin: "0 auto",
      padding: "0 var(--gutter)"
    }
  }, eyebrow ? /*#__PURE__*/React.createElement("div", {
    className: "hh-eyebrow",
    style: {
      marginBottom: 14
    }
  }, eyebrow) : null, title ? /*#__PURE__*/React.createElement("h2", {
    style: {
      fontSize: "var(--display-md)",
      marginBottom: intro ? 12 : 32
    }
  }, title) : null, intro ? /*#__PURE__*/React.createElement("p", {
    style: {
      fontFamily: "var(--font-serif)",
      fontSize: "var(--serif-sm)",
      color: "var(--text-muted)",
      maxWidth: 560,
      marginBottom: 36
    }
  }, intro) : null, children));
}
Object.assign(window, {
  Icon,
  Photo,
  Header,
  Footer,
  Section,
  NAV
});
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/website/Shell.jsx", error: String((e && e.message) || e) }); }

// ui_kits/website/Venue.jsx
try { (() => {
const {
  Button,
  Card,
  CardTitle,
  CardMeta,
  Badge,
  Tag,
  Input,
  Select,
  Tabs
} = window.HotelHallDesignSystem_6ae9d5;
const LAYOUTS = [{
  name: "Banquet",
  seats: "180 seated",
  note: "Round tables of ten, dance floor at the harbour end."
}, {
  name: "Theatre",
  seats: "240 seated",
  note: "Full rows facing the arch, with a lectern and screen."
}, {
  name: "Reception",
  seats: "240 standing",
  note: "Bars at both ends, high tables under the chandelier."
}];
function Venue({
  go
}) {
  const [layout, setLayout] = React.useState("Banquet");
  const active = LAYOUTS.find(l => l.name === layout);
  return /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement("div", {
    style: {
      position: "relative",
      marginTop: -76
    }
  }, /*#__PURE__*/React.createElement(Photo, {
    tone: "deep",
    ratio: "auto",
    radius: "0",
    label: "The Grand Hall \u2014 full bleed",
    style: {
      height: 460,
      alignItems: "flex-end",
      justifyContent: "flex-start"
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      position: "absolute",
      inset: 0,
      background: "var(--scrim-bottom)"
    }
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      position: "relative",
      maxWidth: "var(--container-max)",
      width: "100%",
      margin: "0 auto",
      padding: "0 var(--gutter) 56px"
    }
  }, /*#__PURE__*/React.createElement("div", {
    className: "hh-eyebrow",
    style: {
      color: "var(--gold-400)"
    }
  }, "Celebrate"), /*#__PURE__*/React.createElement("h1", {
    style: {
      color: "#fff",
      fontSize: "var(--display-lg)",
      margin: "16px 0 0"
    }
  }, "The Grand Hall"), /*#__PURE__*/React.createElement("p", {
    style: {
      fontFamily: "var(--font-serif)",
      fontSize: "var(--serif-md)",
      color: "rgba(255,255,255,.86)",
      maxWidth: 520,
      marginTop: 14
    }
  }, "Weddings, banquets and company evenings under the original 1974 arch.")))), /*#__PURE__*/React.createElement(Section, {
    eyebrow: "Layouts",
    title: "Three ways to set the room"
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      display: "grid",
      gridTemplateColumns: "1.15fr 1fr",
      gap: 48,
      alignItems: "start"
    }
  }, /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement("div", {
    style: {
      display: "flex",
      gap: 8,
      marginBottom: 20
    }
  }, LAYOUTS.map(l => /*#__PURE__*/React.createElement(Tag, {
    key: l.name,
    selected: layout === l.name,
    onClick: () => setLayout(l.name)
  }, l.name))), /*#__PURE__*/React.createElement(Photo, {
    label: `${active.name} layout 3:2`,
    ratio: "3 / 2"
  }), /*#__PURE__*/React.createElement("p", {
    style: {
      fontFamily: "var(--font-serif)",
      fontSize: "var(--serif-sm)",
      color: "var(--text-body)",
      marginTop: 18
    }
  }, /*#__PURE__*/React.createElement("strong", {
    style: {
      fontWeight: 500
    }
  }, active.seats, "."), " ", active.note)), /*#__PURE__*/React.createElement(Card, {
    padding: "var(--card-pad-lg)"
  }, /*#__PURE__*/React.createElement("div", {
    className: "hh-eyebrow"
  }, "Request a quote"), /*#__PURE__*/React.createElement(CardTitle, {
    style: {
      marginTop: 10,
      marginBottom: 18
    }
  }, "Tell us about the evening"), /*#__PURE__*/React.createElement("div", {
    style: {
      display: "grid",
      gap: 14
    }
  }, /*#__PURE__*/React.createElement(Input, {
    label: "Your name",
    placeholder: "Full name"
  }), /*#__PURE__*/React.createElement(Input, {
    label: "Email",
    placeholder: "you@example.com"
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      display: "grid",
      gridTemplateColumns: "1fr 1fr",
      gap: 14
    }
  }, /*#__PURE__*/React.createElement(Select, {
    label: "Occasion",
    options: ["Wedding", "Banquet", "Corporate evening", "Conference"]
  }), /*#__PURE__*/React.createElement(Select, {
    label: "Guests",
    options: ["Up to 80", "80–140", "140–180", "180+"]
  })), /*#__PURE__*/React.createElement(Input, {
    label: "Preferred date",
    placeholder: "Aug 12, 2026",
    iconRight: /*#__PURE__*/React.createElement(Icon, {
      name: "calendar",
      size: 16
    })
  }), /*#__PURE__*/React.createElement(Button, {
    variant: "gold",
    fullWidth: true,
    style: {
      marginTop: 4
    }
  }, "Request a quote"), /*#__PURE__*/React.createElement("p", {
    style: {
      fontSize: "var(--text-xs)",
      color: "var(--text-subtle)",
      margin: 0
    }
  }, "We reply within one business day, with a hold on the date for 72 hours."))))), /*#__PURE__*/React.createElement("section", {
    style: {
      background: "var(--surface-sunken)",
      padding: "var(--section-y-tight) 0"
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      maxWidth: "var(--container-max)",
      margin: "0 auto",
      padding: "0 var(--gutter)"
    }
  }, /*#__PURE__*/React.createElement("div", {
    className: "hh-eyebrow",
    style: {
      marginBottom: 26
    }
  }, "Included with the hall"), /*#__PURE__*/React.createElement("div", {
    style: {
      display: "grid",
      gridTemplateColumns: "repeat(4,1fr)",
      gap: 20
    }
  }, [{
    icon: "utensils",
    t: "Service kitchen",
    n: "Plated or buffet, from our own kitchen"
  }, {
    icon: "users",
    t: "Event manager",
    n: "One contact from booking to last dance"
  }, {
    icon: "bed-double",
    t: "Guest room block",
    n: "Ten rooms held at the group rate"
  }, {
    icon: "music",
    t: "Sound & lighting",
    n: "House system, dimmable chandelier"
  }].map(x => /*#__PURE__*/React.createElement(Card, {
    key: x.t
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      color: "var(--gold-700)"
    }
  }, /*#__PURE__*/React.createElement(Icon, {
    name: x.icon,
    size: 22
  })), /*#__PURE__*/React.createElement(CardTitle, {
    style: {
      fontSize: "var(--serif-sm)",
      marginTop: 14
    }
  }, x.t), /*#__PURE__*/React.createElement(CardMeta, {
    style: {
      marginTop: 6
    }
  }, x.n)))))));
}
Object.assign(window, {
  Venue
});
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/website/Venue.jsx", error: String((e && e.message) || e) }); }

// ui_kits/website/data.jsx
try { (() => {
const ROOMS = [{
  id: "harbour",
  name: "Harbour Suite",
  meta: "King bed · Sleeps 2 · 38 m²",
  price: 248,
  rating: 4.8,
  reviews: 218,
  tags: ["Harbour view", "Balcony"],
  note: "Corner windows on the harbour side, with a king bed and a writing desk."
}, {
  id: "garden",
  name: "Garden Double",
  meta: "Queen bed · Sleeps 2 · 26 m²",
  price: 186,
  rating: 4.6,
  reviews: 164,
  tags: ["Quiet wing"],
  note: "Ground floor, opening onto the courtyard. Best for a longer stay."
}, {
  id: "hall",
  name: "Hall Family Room",
  meta: "King + twin · Sleeps 4 · 44 m²",
  price: 312,
  rating: 4.7,
  reviews: 96,
  tags: ["Connecting", "Breakfast"],
  note: "Two rooms joined by a private hallway, with a full bath in each."
}, {
  id: "tower",
  name: "Tower Studio",
  meta: "Queen bed · Sleeps 2 · 22 m²",
  price: 164,
  rating: 4.4,
  reviews: 302,
  tags: ["City view"],
  note: "Compact and high up, with a deep window seat over the old town."
}];
const AMENITIES = [{
  icon: "utensils",
  label: "Harbour restaurant",
  note: "Breakfast 7–10 AM, dinner from 6 PM"
}, {
  icon: "wifi",
  label: "Wi-Fi throughout",
  note: "Included in every rate"
}, {
  icon: "car",
  label: "Valet parking",
  note: "$32 per night"
}, {
  icon: "dumbbell",
  label: "Fitness room",
  note: "Open 24 hours"
}];
Object.assign(window, {
  ROOMS,
  AMENITIES
});
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/website/data.jsx", error: String((e && e.message) || e) }); }

__ds_ns.Badge = __ds_scope.Badge;

__ds_ns.Button = __ds_scope.Button;

__ds_ns.Card = __ds_scope.Card;

__ds_ns.CardTitle = __ds_scope.CardTitle;

__ds_ns.CardMeta = __ds_scope.CardMeta;

__ds_ns.IconButton = __ds_scope.IconButton;

__ds_ns.Tabs = __ds_scope.Tabs;

__ds_ns.Tag = __ds_scope.Tag;

__ds_ns.Tooltip = __ds_scope.Tooltip;

__ds_ns.Dialog = __ds_scope.Dialog;

__ds_ns.Rating = __ds_scope.Rating;

__ds_ns.Toast = __ds_scope.Toast;

__ds_ns.Checkbox = __ds_scope.Checkbox;

__ds_ns.DateField = __ds_scope.DateField;

__ds_ns.Field = __ds_scope.Field;

__ds_ns.Input = __ds_scope.Input;

__ds_ns.Radio = __ds_scope.Radio;

__ds_ns.RadioGroup = __ds_scope.RadioGroup;

__ds_ns.Select = __ds_scope.Select;

__ds_ns.Switch = __ds_scope.Switch;

})();
