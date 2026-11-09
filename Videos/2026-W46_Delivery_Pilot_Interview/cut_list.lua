-- Cut list for 2026-W46 Delivery Pilot Interview
-- Loaded by 5_Symbols/mark_cuts.lua (dofile). Plain Lua data so it runs inside
-- Resolve's Lua console without a JSON library.
--
-- PHRASES MUST MATCH THE RAW RESOLVE TRANSCRIPTION (raw.srt), not the corrected
-- script.md, so avoid words that were corrected (NEM/Marianna, cloud code, ...).
-- Matching ignores case and punctuation and tolerates ~25% word differences
-- for phrases of 4+ words.
--
-- Each cut has one START anchor and one END anchor:
--   from   = phrase  -> cut starts at the FIRST word of the phrase
--   after  = phrase  -> cut starts right AFTER the LAST word of the phrase
--   to     = phrase  -> cut ends at the LAST word of the phrase
--   before = phrase  -> cut ends right BEFORE the FIRST word of the phrase
--   from = "START" / to = "END" mean the start / end of the recording.
-- Cuts are searched in order, each one after the previous match.

return {
  timeline_name = "W46_edit_v1",   -- name of the new timeline apply_cuts.lua builds

  cuts = {
    { id = "C1",  note = "Pre-roll setup chatter",
      from = "START", before = "Okay, hello" },
    { id = "C2",  note = "Redirect: jumped to bots",
      from = "Okay, you jumped already to bots", to = "I think it's too fast" },
    { id = "C3",  note = "AI skills question asked twice - keep 2nd ask",
      from = "Let's talk about AI skills. What does it mean", to = "AI can do much more than that" },
    { id = "C4",  note = "Redirect filler",
      from = "Ok, but let's come back a little bit", before = "there are software programs" },
    { id = "C5",  note = "Yes / back-and-forth",
      after = "help us to understand they all are different", before = "Where is agent in between" },
    { id = "C6",  note = "Stumble: car driver / rider",
      from = "A car driver has more places than a go", to = "rider always depends on the horse" },
    { id = "C7",  note = "Close the pause between paragraphs",
      after = "The plane has more engineering in it. To answer your question", before = "The engineering has to be learned",
      pad = true },
    { id = "C8",  note = "Trim long question",
      from = "I mean that it takes time and as early as we are starting", before = "You have to adopt your mind to that" },
    { id = "C9",  note = "Filler: Great.",
      after = "able to create and operate all day long", before = "Let's talk a few sentences about the workshop",
      pad = true },
    { id = "C10", note = "Unclear managed-service sentence",
      from = "And if the business is not", to = "be able to implement" },
    { id = "C11", note = "Post-roll",
      from = "This could be very long", to = "END" },
  },

  -- Chapter markers (BLUE). Title is used for youtube_chapters.txt.
  chapters = {
    { n = 1,  at = "Okay, hello",                                             title = "Why technology?" },
    { n = 2,  at = "Can you help us to understand the history",               title = "40 years of technology" },
    { n = 3,  at = "Right, it seems that today we don't need programmers",    title = "Do we still need programmers?" },
    { n = 4,  at = "Let's talk about AI skills first",                        title = "Rider, Driver, Pilot" },
    { n = 5,  at = "Okay, can you help us to understand the journey",         title = "The journey to pilot" },
    { n = 6,  at = "There are software programs, there are bots",             title = "Software vs chatbots vs agents" },
    { n = 7,  at = "This bot, when you are saying bot",                       title = "Agent vs bot" },
    { n = 8,  at = "Let's talk a little bit about coding",                    title = "Do we need to learn coding?" },
    { n = 9,  at = "Then we are turning to the subject why continuous learning", title = "Continuous learning" },
    { n = 10, at = "I know that you like to learn a lot",                     title = "Why teach?" },
    { n = 11, at = "Let's talk a little bit about the mind digestion system", title = "Self-learning & COBALTS" },
    { n = 12, at = "Let's talk a few sentences about the workshop",           title = "Cambridge workshops & Skool" },
    { n = 13, at = "Are there any requirements",                              title = "Requirements to join" },
    { n = 14, at = "If someone is thinking, Oh, AI isn't for me",             title = "AI isn't for me" },
  },

  -- Silence tightening from gaps between SRT entries.
  -- Any gap longer than min_gap_s is cut down to keep_s seconds of pause.
  -- Cuts with pad = true also keep keep_s of pause (split half each side).
  silence = { enabled = true, min_gap_s = 0.8, keep_s = 0.4 },
}
