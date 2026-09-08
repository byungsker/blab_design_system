import { renderToStaticMarkup } from "react-dom/server";
import { describe, expect, it } from "vitest";

import {
  BLabButton,
  BLabCard,
  BLabEmptyState,
  BLabErrorState,
  BLabKeyboardAccessoryBar,
  BLabLoadingState,
  BLabTextField,
} from "../src/index";
import { BLabParityFixture } from "../src/fixture";

describe("BLab React public components", () => {
  it("renders the button with the Flutter-aligned variant and accessible state", () => {
    const html = renderToStaticMarkup(
      <BLabButton text="Continue" variant="primary" loading loadingLabel="Saving" />,
    );

    expect(html).toContain('data-blab-component="button"');
    expect(html).toContain('class="blab-button blab-button--primary"');
    expect(html).toContain('aria-busy="true"');
    expect(html).toContain("Saving");
  });

  it("keeps field labels and errors associated in server-rendered markup", () => {
    const html = renderToStaticMarkup(
      <BLabTextField
        id="email"
        label="Email"
        value=""
        onChange={() => undefined}
        error="Email is required"
      />,
    );

    expect(html).toContain('for="email"');
    expect(html).toContain('aria-invalid="true"');
    expect(html).toContain('role="alert"');
    expect(html).toContain("Email is required");
  });

  it("keeps obscure fields single-line like Flutter", () => {
    const html = renderToStaticMarkup(
      <BLabTextField
        ariaLabel="Password"
        value="secret"
        onChange={() => undefined}
        obscureText
        maxLines={4}
      />,
    );

    expect(html).toContain('<input');
    expect(html).toContain('type="password"');
    expect(html).not.toContain("secret");
    expect(html).not.toContain("<textarea");
  });

  it("renders the reusable state and fixture surfaces without product data dependencies", () => {
    const html = renderToStaticMarkup(
      <>
        <BLabCard>Card</BLabCard>
        <BLabLoadingState label="Loading" />
        <BLabEmptyState title="Empty" />
        <BLabErrorState title="Error" message="Message" />
        <BLabParityFixture theme="dark" />
      </>,
    );

    expect(html).toContain('data-blab-theme="dark"');
    expect(html).toContain('data-blab-component="parity-fixture"');
    expect(html).toContain('role="status"');
    expect(html).toContain('role="alert"');
  });

  it("renders keyboard accessory controls with disabled capability state", () => {
    const html = renderToStaticMarkup(
      <BLabKeyboardAccessoryBar
        onDone={() => undefined}
        ariaLabel="Keyboard accessory"
        doneLabel="Done"
        onUndo={() => undefined}
        canUndo={false}
        undoLabel="Undo"
      />,
    );

    expect(html).toContain('data-blab-component="keyboard-accessory-bar"');
    expect(html).toContain('aria-label="Undo"');
    expect(html).toContain('disabled=""');
    expect(html).toContain('aria-label="Done"');
  });
});
