import { useEffect, useRef } from "react";
import type {
  CSSProperties,
  HTMLAttributes,
  KeyboardEventHandler,
} from "react";

export type BLabCardProps = Omit<HTMLAttributes<HTMLDivElement>, "children" | "onClick"> & {
  readonly children: React.ReactNode;
  readonly padding?: CSSProperties["padding"];
  readonly borderRadius?: CSSProperties["borderRadius"];
  readonly onClick?: () => void;
  readonly onLongPress?: () => void;
  readonly disabled?: boolean;
};

export function BLabCard({
  children,
  padding,
  borderRadius,
  onClick,
  onLongPress,
  disabled = false,
  className,
  style,
  onKeyDown: consumerOnKeyDown,
  ...rest
}: BLabCardProps) {
  const longPressTimer = useRef<ReturnType<typeof setTimeout> | undefined>(undefined);
  const longPressed = useRef(false);
  const interactive = Boolean(onClick || onLongPress);

  useEffect(
    () => () => {
      if (longPressTimer.current !== undefined) {
        clearTimeout(longPressTimer.current);
      }
    },
    [],
  );

  const clearLongPress = () => {
    if (longPressTimer.current !== undefined) {
      clearTimeout(longPressTimer.current);
      longPressTimer.current = undefined;
    }
  };

  const handlePointerDown = () => {
    if (disabled || !onLongPress) {
      return;
    }

    longPressed.current = false;
    longPressTimer.current = setTimeout(() => {
      longPressed.current = true;
      onLongPress();
    }, 500);
  };

  const handleClick = () => {
    if (disabled || longPressed.current) {
      longPressed.current = false;
      return;
    }

    onClick?.();
  };

  const handleKeyDown: KeyboardEventHandler<HTMLDivElement> = (event) => {
    consumerOnKeyDown?.(event);
    if (event.defaultPrevented || disabled || !interactive) {
      return;
    }

    if (event.key === "Enter" || event.key === " ") {
      event.preventDefault();
      onClick?.();
    }
  };

  const cardStyle = {
    ...style,
    ...(padding !== undefined ? { padding } : {}),
    ...(borderRadius !== undefined ? { borderRadius } : {}),
  } satisfies CSSProperties;
  const cardClassName = [
    "blab-card",
    interactive ? "blab-card--interactive" : "",
    className ?? "",
  ]
    .filter(Boolean)
    .join(" ");

  return (
    <div
      {...rest}
      className={cardClassName}
      style={cardStyle}
      role={interactive ? "button" : undefined}
      tabIndex={interactive && !disabled ? 0 : undefined}
      aria-disabled={disabled || undefined}
      onPointerDown={handlePointerDown}
      onPointerUp={clearLongPress}
      onPointerCancel={clearLongPress}
      onClick={handleClick}
      onKeyDown={handleKeyDown}
    >
      {children}
    </div>
  );
}
