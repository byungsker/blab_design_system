import type { ButtonHTMLAttributes, ReactNode } from "react";

export const BLabButtonVariant = {
  primary: "primary",
  secondary: "secondary",
  destructive: "destructive",
} as const;

export type BLabButtonVariant = (typeof BLabButtonVariant)[keyof typeof BLabButtonVariant];

export type BLabButtonProps = Omit<
  ButtonHTMLAttributes<HTMLButtonElement>,
  "children" | "onClick" | "type"
> & {
  readonly text?: string;
  readonly children?: ReactNode;
  readonly onClick?: ButtonHTMLAttributes<HTMLButtonElement>["onClick"];
  readonly icon?: ReactNode;
  readonly variant?: BLabButtonVariant;
  readonly isFullWidth?: boolean;
  readonly loading?: boolean;
  readonly loadingLabel?: string;
  readonly type?: NonNullable<ButtonHTMLAttributes<HTMLButtonElement>["type"]>;
};

export function BLabButton({
  text,
  children,
  onClick,
  icon,
  variant = BLabButtonVariant.primary,
  isFullWidth = false,
  loading = false,
  loadingLabel,
  disabled = false,
  type = "button",
  className,
  ...rest
}: BLabButtonProps) {
  const label = children ?? text;
  const buttonClassName = [
    "blab-button",
    `blab-button--${variant}`,
    isFullWidth ? "blab-button--full-width" : "",
    className ?? "",
  ]
    .filter(Boolean)
    .join(" ");

  return (
    <button
      {...rest}
      type={type}
      className={buttonClassName}
      onClick={onClick}
      disabled={disabled || loading}
      aria-busy={loading || undefined}
      data-blab-component="button"
    >
      {loading ? <span className="blab-button__spinner" aria-hidden="true" /> : null}
      {icon && !loading ? <span aria-hidden="true">{icon}</span> : null}
      <span>{loading ? loadingLabel ?? label : label}</span>
    </button>
  );
}
