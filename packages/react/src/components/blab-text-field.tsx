import { useId } from "react";
import type {
  ChangeEvent,
  CSSProperties,
  FocusEventHandler,
  InputHTMLAttributes,
  ReactNode,
} from "react";

export type BLabTextFieldProps = {
  readonly value: string;
  readonly onChange: (event: ChangeEvent<HTMLInputElement | HTMLTextAreaElement>) => void;
  readonly label?: string;
  readonly hintText?: string;
  readonly readOnly?: boolean;
  readonly obscureText?: boolean;
  readonly autofocus?: boolean;
  readonly onTap?: () => void;
  readonly suffixIcon?: ReactNode;
  readonly maxLines?: number;
  readonly error?: string;
  readonly clearLabel?: string;
  readonly onClear?: () => void;
  readonly id?: string;
  readonly name?: string;
  readonly disabled?: boolean;
  readonly required?: boolean;
  readonly autoComplete?: string;
  readonly inputMode?: InputHTMLAttributes<HTMLInputElement>["inputMode"];
  readonly inputType?: InputHTMLAttributes<HTMLInputElement>["type"];
  readonly ariaLabel?: string;
  readonly describedBy?: string;
  readonly onFocus?: FocusEventHandler<HTMLInputElement | HTMLTextAreaElement>;
  readonly onBlur?: FocusEventHandler<HTMLInputElement | HTMLTextAreaElement>;
  readonly className?: string;
  readonly style?: CSSProperties;
};

export function BLabTextField({
  value,
  onChange,
  label,
  hintText,
  readOnly = false,
  obscureText = false,
  autofocus = false,
  onTap,
  suffixIcon,
  maxLines = 1,
  error,
  clearLabel,
  onClear,
  id,
  name,
  disabled = false,
  required = false,
  autoComplete,
  inputMode,
  inputType = "text",
  ariaLabel,
  describedBy,
  onFocus,
  onBlur,
  className,
  style,
}: BLabTextFieldProps) {
  const generatedId = useId();
  const controlId = id ?? `blab-field-${generatedId}`;
  const errorId = `${controlId}-error`;
  const describedByValue = [describedBy, error ? errorId : ""].filter(Boolean).join(" ") || undefined;
  const fieldClassName = ["blab-field", className ?? ""].filter(Boolean).join(" ");
  const controlProps = {
    id: controlId,
    name,
    value,
    placeholder: hintText,
    readOnly,
    autoFocus: autofocus,
    disabled,
    required,
    autoComplete,
    inputMode,
    "aria-label": ariaLabel,
    "aria-describedby": describedByValue,
    "aria-invalid": error ? true : undefined,
    "aria-errormessage": error ? errorId : undefined,
    onChange,
    onClick: onTap,
    onFocus,
    onBlur,
    className: "blab-field__control",
  };

  return (
    <div className={fieldClassName} style={style} data-blab-component="text-field">
      {label ? <label className="blab-field__label" htmlFor={controlId}>{label}</label> : null}
      <div className="blab-field__shell">
        {maxLines > 1 ? (
          <textarea {...controlProps} rows={maxLines} />
        ) : (
          <input {...controlProps} type={obscureText ? "password" : inputType} />
        )}
        {suffixIcon ? <span className="blab-field__suffix">{suffixIcon}</span> : null}
        {value && onClear && clearLabel && !readOnly && !disabled ? (
          <button
            className="blab-field__clear"
            type="button"
            aria-label={clearLabel}
            onClick={onClear}
          >
            ×
          </button>
        ) : null}
      </div>
      {error ? <span className="blab-field__error" id={errorId} role="alert">{error}</span> : null}
    </div>
  );
}
