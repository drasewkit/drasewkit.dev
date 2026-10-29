import { Hono } from 'hono'
import { zValidator } from '@hono/zod-validator'
import * as z from 'zod'

export const contactSchema = z.object({
  name: z.string().trim().min(1).max(100),
  email: z.email().max(254),
  message: z.string().trim().min(1).max(5000),
})

export const contact = new Hono<{ Bindings: CloudflareBindings }>().post(
  '/',
  zValidator('json', contactSchema, (result, c) => {
    if (!result.success) {
      return c.json(
        { ok: false, errors: z.flattenError(result.error).fieldErrors },
        422,
      )
    }
  }),
  (c) => {
    const input = c.req.valid('json')

    // TODO: Turnstile の検証、Resend での送信
    console.log('contact received', { name: input.name })

    return c.json({ ok: true })
  },
)
