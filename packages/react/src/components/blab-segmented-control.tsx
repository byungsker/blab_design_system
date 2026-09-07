import type { CSSProperties, KeyboardEventHandler } from "react";

export type BLabSegmentedItem<T> = {
  readonly value: T;
  readonly label: string;
};

export type BLabSegmentedControlProps<T> = {
  readonly items: readonly BLabSegmentedItem<T>[];
  readonly selectedValue: T;
  readonly onChanged: (value: T) => void;
  readonly height?: number;
  readonly borderRadius?: number;
  readonly padding?: number;
  readonly ariaLabel?: string;
  readonly className?: string;
};

export function BLabSegmentedControl<T>({
  items,
  selectedValue,
  onChanged,
  height = 40,
  borderRadius = 10,
  padding = 3,
  ariaLabel,
  className,
}: BLabSegmentedControlProps<T>) {
  const handleKeyDown: KeyboardEventHandler<HTMLButtonElement> = (event) => {
    const selectedIndex = items.findIndex((item) => item.value === selectedValue);
    if (selectedIndex < 0 || items.length === 0) {
      return;
    }

    const nextIndex =
      event.key === "ArrowRight"
        ? (selectedIndex + 1) % items.length
        : event.key === "ArrowLeft"
          ? (selectedIndex - 1 + items.length) % items.length
          : undefined;

    if (nextIndex === undefined) {
      return;
    }

    event.preventDefault();
    const nextItem = items[nextIndex];
    if (nextItem) {
      onChanged(nextItem.value);
    }
  };

  const style: CSSProperties & {
    readonly "--blab-segmented-height": string;
    readonly "--blab-segmented-radius": string;
    readonly "--blab-segmented-padding": string;
  } = {
    "--blab-segmented-height": `${height}px`,
    "--blab-segmented-radius": `${borderRadius}px`,
    "--blab-segmented-padding": `${padding}px`,
  };

  return (
    <div
      className={["blab-segmented-control", className ?? ""].filter(Boolean).join(" ")}
      style={style}
      role="group"
      aria-label={ariaLabel}
    >
      {items.map((item, index) => {
        const selected = item.value === selectedValue;
        return (
          <button
            key={`${item.label}-${index}`}
            className="blab-segmented-control__item"
            type="button"
            aria-pressed={selected}
            tabIndex={selected ? 0 : -1}
            onClick={() => onChanged(item.value)}
            onKeyDown={handleKeyDown}
          >
            {item.label}
          </button>
        );
      })}
    </div>
  );
}
